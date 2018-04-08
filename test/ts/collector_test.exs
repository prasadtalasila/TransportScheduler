defmodule CollectorTest do
  @moduledoc """
  Define tests for the Query Collector Module
  """

  use ExUnit.Case, async: true
  import Mox
  alias Station.QueryCollector, as: QC
  alias Util.Itinerary, as: Itinerary
  alias Util.Query, as: Query
  alias Util.Connection, as: Connection
  alias Util.Preference, as: Preference

  @dependency %{
    uqc: MockUQC,
    itinerary: MockItinerary,
    registry: MockRegister,
    station: MockStation
  }

  test "Normal working of Query Collector with number of completed itineraries equal to max_itineraries" do
    query = %Query{
      qid: "0300",
      src_station: 0,
      dst_station: 3,
      arrival_time: 0,
      end_time: 999_999
    }

    preference = %Preference{day: 0}

    itinerary = Itinerary.new(query, preference)

    # Set options for QC process
    opts = %{max_itineraries: 5, timeout: 100}

    dependency = @dependency

    # Get 5 random terminal itineraries of length 4
    itinerary1 = get_terminal_itinerary(query, preference, 4)
    itinerary2 = get_terminal_itinerary(query, preference, 4)
    itinerary3 = get_terminal_itinerary(query, preference, 4)
    itinerary4 = get_terminal_itinerary(query, preference, 4)
    itinerary5 = get_terminal_itinerary(query, preference, 4)

    result = [itinerary5, itinerary4, itinerary3, itinerary2, itinerary1]

    station_pid = :c.pid(0, 99, 1)
    station_code = query.src_station
    qid = query.qid

    {:ok, pid} = QC.start_link(itinerary, opts, dependency)

    MockUQC
    |> expect(:receive_search_results, fn ^result -> nil end)

    MockRegister
    |> expect(:lookup_code, fn ^station_code -> station_pid end)
    |> expect(:unregister_query, fn ^qid -> nil end)
    |> expect(:lookup_query_id, 5, fn ^qid -> pid end)

    MockStation
    |> expect(:send_query, fn ^station_pid, ^itinerary -> nil end)

    MockItinerary
    |> expect(:get_query, fn {query, _, _} -> query end)
    |> expect(:get_query_id, 7, fn {query, _, _} -> query.qid end)

    # Give access to UQC process to mocks.
    allow(MockUQC, self(), pid)
    allow(MockItinerary, self(), pid)
    allow(MockRegister, self(), pid)
    allow(MockStation, self(), pid)

    # Initialise Query
    QC.search_itinerary(pid)

    QC.collect(itinerary1, dependency)
    QC.collect(itinerary2, dependency)
    QC.collect(itinerary3, dependency)
    QC.collect(itinerary4, dependency)
    QC.collect(itinerary5, dependency)

    # Wait for the station to terminate
    wait_for_process_termination(pid)

    verify!(MockStation)
    verify!(MockUQC)
    verify!(MockRegister)
    verify!(MockItinerary)
  end

  test "Normal working of Query Collector with completed itineraries not exceeding max_itineraries" do
    query = %Query{
      qid: "0300",
      src_station: 0,
      dst_station: 3,
      arrival_time: 0,
      end_time: 999_999
    }

    preference = %Preference{day: 0}

    itinerary = Itinerary.new(query, preference)

    # Set options for QC process
    opts = %{max_itineraries: 5, timeout: 100}

    dependency = @dependency

    # Get 5 random terminal itineraries of length 4
    itinerary1 = get_terminal_itinerary(query, preference, 4)
    itinerary2 = get_terminal_itinerary(query, preference, 4)
    itinerary3 = get_terminal_itinerary(query, preference, 4)

    result = [itinerary3, itinerary2, itinerary1]

    station_pid = :c.pid(0, 99, 1)
    station_code = query.src_station
    qid = query.qid

    {:ok, pid} = QC.start_link(itinerary, opts, dependency)

    MockUQC
    |> expect(:receive_search_results, fn ^result -> nil end)

    MockRegister
    |> expect(:lookup_code, fn ^station_code -> station_pid end)
    |> expect(:unregister_query, fn ^qid -> nil end)
    |> expect(:lookup_query_id, 3, fn ^qid -> pid end)

    MockStation
    |> expect(:send_query, fn ^station_pid, ^itinerary -> nil end)

    MockItinerary
    |> expect(:get_query, fn {query, _, _} -> query end)
    |> expect(:get_query_id, 5, fn {query, _, _} -> query.qid end)

    # Give access to UQC process to mocks.
    allow(MockUQC, self(), pid)
    allow(MockItinerary, self(), pid)
    allow(MockRegister, self(), pid)
    allow(MockStation, self(), pid)

    # Initialise Query
    QC.search_itinerary(pid)

    QC.collect(itinerary1, dependency)
    QC.collect(itinerary2, dependency)
    QC.collect(itinerary3, dependency)

    # Wait for the station to terminate
    wait_for_process_termination(pid)

    verify!(MockStation)
    verify!(MockUQC)
    verify!(MockRegister)
    verify!(MockItinerary)
  end

  def get_terminal_itinerary(query, preference, n) when n >= 0 do
    route = loop(n, [], query.src_station)
    last_link = List.first(route)
    src_station = last_link.dst_station
    dst_station = query.dst_station
    dept_time = :rand.uniform(10)
    arrival_time = :rand.uniform(10)
    vid = Integer.to_string(:rand.uniform(10_000))
    mode_of_transport = Integer.to_string(:rand.uniform(10_000))

    last_connection = %Connection{
      vehicleID: vid,
      src_station: src_station,
      mode_of_transport: mode_of_transport,
      dst_station: dst_station,
      dept_time: dept_time,
      arrival_time: arrival_time
    }

    {query, [last_connection | route], preference}
  end

  def loop(n, acc, src_station) when n > 0 do
    vid = Integer.to_string(:rand.uniform(10_000))
    mode_of_transport = Integer.to_string(:rand.uniform(10_000))
    dst_station = src_station + 1
    dept_time = :rand.uniform(10)
    arrival_time = :rand.uniform(10)

    connection = %Connection{
      vehicleID: vid,
      src_station: src_station,
      mode_of_transport: mode_of_transport,
      dst_station: dst_station,
      dept_time: dept_time,
      arrival_time: arrival_time
    }

    loop(n - 1, [connection | acc], dst_station)
  end

  def loop(0, acc, _), do: acc

  def wait_for_process_termination(pid) do
    if Process.alive?(pid) do
      Process.sleep(10)
      wait_for_process_termination(pid)
    end
  end
end
