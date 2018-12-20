defmodule NetworkConstructorTest do
  @moduledoc """
  Module to test the Network Constructor.
  """

  use ExUnit.Case, async: true
  import Mox
  alias Station.QueryCollector, as: QueryCollector
  alias Util.Connection, as: Connection
  alias Util.Dependency, as: Dependency
  alias Util.Itinerary, as: Itinerary
  alias Util.Preference, as: Preference
  alias Util.Query, as: Query
  alias Util.Registry, as: Registry
  alias Util.StationStruct, as: StationStruct

  # Test to check if the station code and corresponding PIDs are there in registry

  test "registering of station code and corresponding pid" do
    {:ok, ip_pid} = InputParser.start_link([])

    stn_map = InputParser.get_station_map(ip_pid)

    Enum.each(stn_map, fn {stn_name, stn_code} ->
      assert Registry.lookup_code(stn_code) != nil
    end)
  end

  # Test to see if data can be retrieved from the station correctly
  test "retrieving the given schedule" do
    # Station Schedule
    schedule = [
      %{
        vehicleID: "99",
        src_station: 0,
        mode_of_transport: "train",
        dst_station: 1,
        dept_time: 10_000,
        arrival_time: 20_000
      }
    ]

    pid = Registry.lookup_code(0)

    # Retrieve Time Table
    assert Station.get_timetable(pid) == schedule
  end

  # Test to see if the station schedule can be updated
  test "updating the station schedule" do
    # Station Schedule
    schedule = [
      %Connection{
        vehicleID: "100",
        src_station: 1,
        mode_of_transport: "bus",
        dst_station: 2,
        dept_time: 25_000,
        arrival_time: 35_000
      }
    ]

    new_schedule = [
      %Connection{
        vehicleID: "88",
        src_station: 1,
        mode_of_transport: "train",
        dst_station: 2,
        dept_time: 12_000,
        arrival_time: 24_000
      },
      %Connection{
        vehicleID: "100",
        src_station: 1,
        mode_of_transport: "bus",
        dst_station: 2,
        dept_time: 25_000,
        arrival_time: 35_000
      }
    ]

    [tuple] = Supervisor.which_children(InputParser.Supervisor)
    ip_pid = elem(tuple, 1)

    station_state = InputParser.get_station_struct(ip_pid, "Mumbai")

    dependency = %Dependency{
      station: MockStation,
      registry: MockRegister,
      collector: MockCollector,
      itinerary: Itinerary
    }

    pid = Registry.lookup_code(1710)

    new_station_state = %{station_state | schedule: new_schedule}

    Station.update(pid, new_station_state)

    # Retrieve the Time Table and check if it has been updated
    assert Station.get_timetable(pid) == new_schedule
  end

  test "Receive a itinerary search query" do
    # Set function parameters to arbitrary values.
    # effect only after the station has received the query.
    query =
      Itinerary.new(
        %Query{
          qid: "0300",
          src_station: 0,
          dst_station: 3,
          arrival_time: 0,
          end_time: 999_999
        },
        %Preference{day: 0}
      )

    test_proc = self()

    # Create NetworkConstructor Mock
    MockUQC
    |> expect(:receive_search_results, fn _ ->
      send(test_proc, :query_received)
      false
    end)

    opts = %{max_itineraries: 1, timeout: 100}

    pid = Registry.lookup_code(1)

    dependency = %{
      station: Station,
      registry: Registry,
      uqc: MockUQC,
      itinerary: Itinerary
    }

    # Send query to station
    # Station.send_query(pid, query)

    {:ok, qc_pid} = QueryCollector.start_link(query, opts, dependency)

    Registry.register_query("0300", qc_pid)

    allow(MockUQC, test_proc, qc_pid)

    QueryCollector.search_itinerary(qc_pid)

    QueryCollector.collect(query, dependency)

    assert_receive :query_received
  end
end
