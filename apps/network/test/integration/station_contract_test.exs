defmodule StationContractTest do
  @moduledoc """
  Module to test Station.
  Tests that the station follows the behavioural contract defined.
  """

  use ExUnit.Case, async: true
  import Mox
  alias Util.Connection, as: Connection
  alias Util.Dependency, as: Dependency
  alias Util.Itinerary, as: Itinerary
  alias Util.Preference, as: Preference
  alias Util.Query, as: Query
  alias Util.StationStruct, as: StationStruct

  # Test to see if data can be retrieved from the station correctly
  test "retrieving the given schedule" do
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

    station_state = %StationStruct{
      loc_vars: %{delay: 0.12, congestion: "low", disturbance: "no"},
      schedule: schedule,
      station_number: 1710,
      station_name: "Mumbai",
      congestion_low: 3,
      choose_fn: 2
    }

    # Start the server
    dependency = %Dependency{
      station: MockStation,
      registry: MockRegister,
      collector: MockCollector,
      itinerary: Itinerary
    }

    {:ok, pid} = start_supervised({Station, [station_state, dependency]})

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
      %
      {
        vehicleID: "100",
        src_station: 1,
        mode_of_transport: "bus",
        dst_station: 2,
        dept_time: 25_000,
        arrival_time: 35_000
      }
    ]

    station_state = %StationStruct{
      loc_vars: %{delay: 0.12, congestion: "low", disturbance: "no"},
      schedule: schedule,
      station_number: 1710,
      station_name: "Mumbai",
      congestion_low: 3,
      choose_fn: 2
    }

    dependency = %Dependency{
      station: MockStation,
      registry: MockRegister,
      collector: MockCollector,
      itinerary: Itinerary
    }

    # Start the server
    {:ok, pid} = start_supervised({Station, [station_state, dependency]})

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

    # Any errors due to invalid values do not matter as they will come into

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

    test_proc = self()

    # Create NetworkConstructor Mock
    MockRegister
    |> expect(:check_active, fn _ ->
      send(test_proc, :query_received)
      false
    end)

    dependency = %Dependency{
      station: MockStation,
      registry: MockRegister,
      collector: MockCollector,
      itinerary: Itinerary
    }

    # start station
    {:ok, pid} = Station.start_link([station_state, dependency])

    # Give The Station Process access to mocks defined in the test process
    allow(MockRegister, test_proc, pid)
    allow(MockCollector, test_proc, pid)
    allow(MockStation, test_proc, pid)

    # Send query to station
    Station.send_query(pid, query)
    # Stop station normally
    Station.stop(pid)

    # Wait for the Station process to terminate
    wait_for_process_termination(pid)

    assert_receive :query_received
  end

  test "Send completed search query to neighbours" do
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
    |> expect(:check_active, fn _ -> true end)

    MockStation
    |> expect(:send_query, fn ^test_proc, _ ->
      send(test_proc, :query_forwarded)
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

    assert_receive :query_forwarded
  end

  test "The correct itinerary is forwarded to the next station" do
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

    proper_itinerary =
      Itinerary.add_link(itinerary, %Connection{
        vehicleID: "100",
        src_station: 1,
        mode_of_transport: "bus",
        dst_station: 2,
        dept_time: 25_000,
        arrival_time: 35_000
      })

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
    |> expect(:send_query, fn ^test_proc, itinerary ->
      send(test_proc, {:itinerary_received, itinerary})
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

    assert_receive({:itinerary_received, ^proper_itinerary})
  end

  test "Terminated queries are handed over to query collector with correct itinerary" do
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

    itinerary =
      Itinerary.new(
        %Query{
          qid: "0100",
          src_station: 0,
          dst_station: 1,
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

    # Define the expectation for the Mock of the Network Constructor
    MockRegister
    |> expect(:check_active, fn _ -> true end)

    # Define the expectation for the Mock of the Query Collector
    MockCollector
    |> expect(:collect, fn itinerary, ^dependency ->
      send(test_proc, {:itinerary_received, itinerary})
    end)

    MockStation
    |> expect(:send_query, fn _, _ ->
      send(test_proc, :collected_query_forwarded)
    end)

    {:ok, pid} = Station.start_link([station_state, dependency])

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

    # Assert that the query collector collects the itinerary
    assert_receive({:itinerary_received, ^itinerary})
    refute_receive :collected_query_forwarded
  end

  def wait_for_process_termination(pid) do
    if Process.alive?(pid) do
      :timer.sleep(10)
      wait_for_process_termination(pid)
    end
  end
end
