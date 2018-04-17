defmodule StationProcessingTest do
  @moduledoc """
  Module to test Station.
  Tests that the station properly
  distinguish between valid and invalid queries.
  """

  use ExUnit.Case, async: true
  import Mox
  alias Util.Dependency, as: Dependency
  alias Util.Itinerary, as: Itinerary
  alias Util.Query, as: Query
  alias Util.Connection, as: Connection
  alias Util.Preference, as: Preference
  alias Util.StationStruct, as: StationStruct

  test "Does not forward stale queries" do
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
      station_number: 1,
      congestion_low: 4,
      choose_fn: 1
    }

    # Station state of Neighbour : %StationStruct{loc_vars: %{"delay": 0.38,
    # 	"congestion": "low", "disturbance": "no"},
    # 	schedule: [], congestion_low: 4, choose_fn: 1}

    itinerary =
      Itinerary.new(
        %Query{
          qid: "0300",
          src_station: 0,
          dst_station: 3,
          arrival_time: 0,
          end_time: 999_999
        },
        [
          %Connection{
            vehicleID: "99",
            src_station: 0,
            mode_of_transport: "train",
            dst_station: 1,
            dept_time: 10_000,
            arrival_time: 20_000
          }
        ],
        %Preference{day: 0}
      )

    test_proc = self()

    dependency = %Dependency{
      station: MockStation,
      registry: MockRegister,
      collector: MockCollector,
      itinerary: Itinerary
    }

    {:ok, pid} = Station.start_link([station_state, dependency])

    # Define the expectation for the Mock of the Network Constructor
    MockRegister
    |> expect(:lookup_code, fn _ -> test_proc end)
    |> expect(:check_active, fn _ -> false end)

    MockStation
    |> expect(:send_query, fn _, _ ->
      send(test_proc, :stale_query_forwarded)
    end)

    # Give The Station Process access to mocks defined in the test process
    allow(MockRegister, test_proc, pid)
    allow(MockCollector, test_proc, pid)
    allow(MockStation, test_proc, pid)

    # Send query to station
    Station.send_query(pid, itinerary)
    # Stop station normally
    Station.stop(pid)

    # Wait for the Station process to terminate
    wait_for_process_termination(pid)

    refute_receive :stale_query_forwarded
  end

  test "Does not forward queries with self loops" do
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
      station_number: 1,
      congestion_low: 4,
      choose_fn: 1
    }

    # Station state of Neighbour : %StationStruct{loc_vars: %{"delay": 0.38,
    # 	"congestion": "low", "disturbance": "no"},
    # 	schedule: [], congestion_low: 4, choose_fn: 1}

    itinerary =
      Itinerary.new(
        %Query{
          qid: "0300",
          src_station: 1,
          dst_station: 3,
          arrival_time: 0,
          end_time: 999_999
        },
        [
          %Connection{
            vehicleID: "100",
            src_station: 2,
            mode_of_transport: "train",
            dst_station: 1,
            dept_time: 25_000,
            arrival_time: 30_000
          },
          %Connection{
            vehicleID: "99",
            src_station: 1,
            mode_of_transport: "train",
            dst_station: 2,
            dept_time: 10_000,
            arrival_time: 20_000
          }
        ],
        %Preference{day: 0}
      )

    test_proc = self()

    dependency = %Dependency{
      station: MockStation,
      registry: MockRegister,
      collector: MockCollector,
      itinerary: Itinerary
    }

    {:ok, pid} = Station.start_link([station_state, dependency])

    # Define the expectation for the Mock of the Network Constructor
    MockRegister
    |> expect(:lookup_code, fn _ -> test_proc end)
    |> expect(:check_active, fn _ -> true end)

    MockStation
    |> expect(:send_query, fn _, _ ->
      send(test_proc, :query_with_self_loops_forwarded)
    end)

    # Give The Station Process access to mocks defined in the test process
    allow(MockRegister, test_proc, pid)
    allow(MockCollector, test_proc, pid)
    allow(MockStation, test_proc, pid)

    # Send query to station
    Station.send_query(pid, itinerary)
    # Stop station normally
    Station.stop(pid)

    # Wait for the Station process to terminate
    wait_for_process_termination(pid)

    refute_receive :query_with_self_loops_forwarded
  end

  test "Incorrectly received queries are discarded" do
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
      station_number: 1,
      congestion_low: 4,
      choose_fn: 1
    }

    # Station state of Neighbour : %StationStruct{loc_vars: %{"delay": 0.38,
    # 	"congestion": "low", "disturbance": "no"},
    # 	schedule: [], congestion_low: 4, choose_fn: 1}

    itinerary =
      Itinerary.new(
        %Query{
          qid: "0300",
          src_station: 1,
          dst_station: 3,
          arrival_time: 0,
          end_time: 999_999
        },
        [
          %Connection{
            vehicleID: "99",
            src_station: 1,
            mode_of_transport: "train",
            dst_station: 11,
            dept_time: 10_000,
            arrival_time: 20_000
          }
        ],
        %Preference{day: 0}
      )

    test_proc = self()

    dependency = %Dependency{
      station: MockStation,
      registry: MockRegister,
      collector: MockCollector,
      itinerary: Itinerary
    }

    {:ok, pid} = Station.start_link([station_state, dependency])

    # Define the expectation for the Mock of the Network Constructor
    MockRegister
    |> expect(:lookup_code, fn _ -> test_proc end)
    |> expect(:check_active, fn _ -> true end)

    MockStation
    |> expect(:send_query, fn _, _ ->
      send(test_proc, :incorrect_query_forwarded)
    end)

    # Give The Station Process access to mocks defined in the test process
    allow(MockRegister, test_proc, pid)
    allow(MockCollector, test_proc, pid)
    allow(MockStation, test_proc, pid)

    # Send query to station
    Station.send_query(pid, itinerary)
    # Stop station normally
    Station.stop(pid)

    # Wait for the Station process to terminate
    wait_for_process_termination(pid)

    refute_receive :incorrect_query_forwarded
  end

  test "No query is forwarded from a Station with no viable paths
  (no viable neighbouring station)." do
    station_state = %StationStruct{
      loc_vars: %{delay: 0.38, congestion: "low", disturbance: "no"},
      schedule: [
        %Connection{
          vehicleID: "100",
          src_station: 1,
          mode_of_transport: "bus",
          dst_station: 2,
          dept_time: 15_000,
          arrival_time: 35_000
        }
      ],
      station_number: 1,
      congestion_low: 4,
      choose_fn: 1
    }

    # Station state of Neighbour : %StationStruct{loc_vars: %{"delay": 0.38,
    # 	"congestion": "low", "disturbance": "no"},
    # 	schedule: [], congestion_low: 4, choose_fn: 1}

    itinerary =
      Itinerary.new(
        %Query{
          qid: "0300",
          src_station: 0,
          dst_station: 3,
          arrival_time: 0,
          end_time: 25_000
        },
        [
          %Connection{
            vehicleID: "99",
            src_station: 0,
            mode_of_transport: "train",
            dst_station: 1,
            dept_time: 10_000,
            arrival_time: 20_000
          }
        ],
        %Preference{day: 0}
      )

    test_proc = self()

    dependency = %Dependency{
      station: MockStation,
      registry: MockRegister,
      collector: MockCollector,
      itinerary: Itinerary
    }

    {:ok, pid} = Station.start_link([station_state, dependency])

    # Define the expectation for the Mock of the Network Constructor
    MockRegister
    |> expect(:lookup_code, fn _ -> test_proc end)
    |> expect(:check_active, fn _ -> true end)

    MockStation
    |> expect(:send_query, fn _, _ ->
      send(test_proc, :incorrect_query_forwarded)
    end)

    # Give The Station Process access to mocks defined in the test process
    allow(MockRegister, test_proc, pid)
    allow(MockCollector, test_proc, pid)
    allow(MockStation, test_proc, pid)

    # Send query to station
    Station.send_query(pid, itinerary)
    # Stop station normally
    Station.stop(pid)

    # Wait for the Station process to terminate
    wait_for_process_termination(pid)

    refute_receive :incorrect_query_forwarded
  end

  def wait_for_process_termination(pid) do
    if Process.alive?(pid) do
      :timer.sleep(10)
      wait_for_process_termination(pid)
    end
  end
end
