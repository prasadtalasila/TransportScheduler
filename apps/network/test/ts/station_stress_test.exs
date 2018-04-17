defmodule StationStressTest do
  @moduledoc """
  Tests for perfomance of the Station.
  """
  use ExUnit.Case, async: true
  import Mox
  alias Util.Dependency, as: Dependency
  alias Util.Itinerary, as: Itinerary
  alias Util.Query, as: Query
  alias Util.Connection, as: Connection
  alias Util.Preference, as: Preference
  alias Util.StationStruct, as: StationStruct

  # Test to check if the station consumes a given number of
  # streams within a stipulated amount of time.
  @tag :slow
  test "Consumes rapid stream of mixed input queries" do
    query =
      Itinerary.new(
        %Query{
          qid: "0100",
          src_station: 0,
          dst_station: 1,
          arrival_time: 0,
          end_time: 999_999
        },
        %Preference{day: 0}
      )

    station_state = %StationStruct{
      loc_vars: %{delay: 0.38, congestion: "low", disturbance: "no"},
      schedule: [
        %Connection{
          vehicleID: "100",
          src_station: 1,
          mode_of_transport: "bus",
          dst_station: 2,
          dept_time: 25_000,
          arrival_time: 35_000
        }
      ],
      congestion_low: 4,
      choose_fn: 1
    }

    test_proc = self()

    dependency = %Dependency{
      station: MockStation,
      registry: MockRegister,
      collector: MockCollector,
      itinerary: Itinerary
    }

    # Start station
    {:ok, pid} = Station.start_link([station_state, dependency])

    # Define the expectation for the Mock of the Network Constructor
    MockRegister
    |> stub(:lookup_code, fn _ -> test_proc end)
    |> stub(:check_active, fn _ ->
      true
    end)

    MockStation
    |> stub(:send_query, fn _, _ -> nil end)

    # Give The Station Process access to mocks defined in the test process
    allow(MockRegister, test_proc, pid)
    allow(MockCollector, test_proc, pid)
    allow(MockStation, test_proc, pid)

    # Send 1000 queries
    send_message(query, 1000, pid)

    # Sleep for 1000 milliseconds
    :timer.sleep(1000)

    # Check if length of message queue is 0
    {:message_queue_len, queue_len} =
      :erlang.process_info(pid, :message_queue_len)

    assert queue_len == 0

    # Send 10_000 queries
    send_message(query, 10_000, pid)

    :timer.sleep(1000)

    {:message_queue_len, queue_len} =
      :erlang.process_info(pid, :message_queue_len)

    assert queue_len == 0

    # Send 10_000 queries
    send_message(query, 100_000, pid)

    :timer.sleep(1000)

    {:message_queue_len, queue_len} =
      :erlang.process_info(pid, :message_queue_len)

    assert queue_len != 0

    Station.stop(pid)
  end

  def send_message(_msg, 0, _pid) do
  end

  # A function to send 'n' number of messages to given pid
  def send_message(msg, n, pid) do
    Station.send_query(pid, msg)
    send_message(msg, n - 1, pid)
  end
end
