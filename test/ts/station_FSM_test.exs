defmodule StationFSMTest do
  @moduledoc """
  Test suite for the StationFsm module
  """

  use ExUnit.Case, async: true
  import Mox
  alias Station.FSM, as: FSM
  alias Util.Dependency, as: Dependency
  alias Util.Itinerary, as: Itinerary
  alias Util.Query, as: Query
  alias Util.Connection, as: Connection
  alias Util.Preference, as: Preference
  alias Util.StationStruct, as: StationStruct

  # Test 1
  # Check if initial state is 'start' and initial data
  # is an empty list
  test "Check configuration of initial state" do
    # Create new station and query for state and data
    station_fsm = FSM.new()

    initial_state = FSM.state(station_fsm)
    initial_data = FSM.data(station_fsm)

    assert initial_state == :start
    assert initial_data == []
  end

  # Test 2

  # Check if given parameters are taken as input by the Fsm when
  # transitioning from 'start' to 'ready' state

  test "Check transition from start to ready state on input data" do
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

    dependency = %Dependency{
      station: MockStation,
      registry: MockRegister,
      collector: MockCollector,
      itinerary: Util.Itinerary
    }

    # Create new station and query for state and data
    station_fsm = FSM.initialise_fsm([station_state, dependency])

    assert FSM.state(station_fsm) == :ready
    assert FSM.data(station_fsm) == [station_state, dependency]
  end

  # Test 3

  # Check if update of variables takes place when in 'ready' state
  # and the new variables take the place of the old station variables

  test "Update variables in 'ready' state" do
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

    dependency = %Dependency{
      station: MockStation,
      registry: MockRegister,
      collector: MockCollector,
      itinerary: Util.Itinerary
    }

    # Create new station and query for state and data
    station_fsm = FSM.initialise_fsm([station_state, dependency])

    # Update Station State to new value
    station_state = %{station_state | schedule: []}
    station_fsm = FSM.update(station_fsm, station_state)

    assert FSM.state(station_fsm) == :ready
    assert FSM.data(station_fsm) == [station_state, dependency]
  end

  # Test 4

  # Check if Fsm transitions from 'ready' state to 'query_rcvd' state
  # when given a query as an input

  test "Receive query in 'ready' state" do
    # Itinerary which is received
    itinerary =
      Itinerary.new(
        %Query{qid: "0300", src_station: 0, dst_station: 3, arrival_time: 0},
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
        %Preference{day: 0, mode_of_transport: "bus"}
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
      station_number: 1,
      congestion_low: 4,
      choose_fn: 1
    }

    dependency = %Dependency{
      station: MockStation,
      registry: MockRegister,
      collector: MockCollector,
      itinerary: Util.Itinerary
    }

    # New Fsm
    station_fsm = FSM.initialise_fsm([station_state, dependency])

    station_fsm = FSM.query_input(station_fsm, itinerary)

    # Assertion on state
    assert FSM.state(station_fsm) == :query_rcvd

    # Assertions on data
    assert FSM.data(station_fsm) == [itinerary, station_state, dependency]
  end

  # Test 5
  # check_query_status function of the 'query_rcvd' state on query with self
  # loops

  test "Check status of query with self-loop in 'query_rcvd' state" do
    station_state = %StationStruct{
      loc_vars: %{delay: 0.38, congestion: "low", disturbance: "no"},
      schedule: [
        %Connection{
          vehicleID: "100",
          src_station: 2,
          mode_of_transport: "bus",
          dst_station: 0,
          dept_time: 25_000,
          arrival_time: 35_000
        }
      ],
      station_number: 2,
      congestion_low: 4,
      choose_fn: 1
    }

    itinerary =
      Itinerary.new(
        %Query{qid: "0300", src_station: 0, dst_station: 7, arrival_time: 0},
        [
          %Connection{
            vehicleID: "99",
            src_station: 0,
            mode_of_transport: "train",
            dst_station: 1,
            dept_time: 10_000,
            arrival_time: 20_000
          },
          %Connection{
            vehicleID: "100",
            src_station: 1,
            mode_of_transport: "train",
            dst_station: 2,
            dept_time: 20_000,
            arrival_time: 25_000
          },
          %Connection{
            vehicleID: "101",
            src_station: 2,
            mode_of_transport: "train",
            dst_station: 3,
            dept_time: 25_000,
            arrival_time: 27_000
          }
        ],
        %Preference{day: 0, mode_of_transport: "bus"}
      )

    # Mock register for mocking the NC
    MockRegister
    |> expect(:check_active, fn _ -> true end)

    dependency = %Dependency{
      station: MockStation,
      registry: MockRegister,
      collector: MockCollector,
      itinerary: Util.Itinerary
    }

    # New Fsm
    station_fsm = FSM.initialise_fsm([station_state, dependency])

    station_fsm =
      station_fsm
      |> FSM.query_input(itinerary)
      |> FSM.check_query_status()

    # Assertion on state
    assert FSM.state(station_fsm) == :ready
  end

  # Test 6

  # Check if a query with the wrong destination station is handled
  # correctly by the Fsm

  test "Check status of query with wrong dst in 'query_rcvd' state" do
    # station_number of the station is set to 1
    station_state = %StationStruct{
      loc_vars: %{delay: 0.38, congestion: "low", disturbance: "no"},
      schedule: [
        %Connection{
          vehicleID: "100",
          src_station: 1,
          mode_of_transport: "bus",
          dst_station: 0,
          dept_time: 25_000,
          arrival_time: 35_000
        }
      ],
      station_number: 1,
      congestion_low: 4,
      choose_fn: 1
    }

    # Query with different dst_station
    itinerary =
      Itinerary.new(
        %Query{qid: "0300", src_station: 0, dst_station: 3, arrival_time: 0},
        [
          %Connection{
            vehicleID: "99",
            src_station: 0,
            mode_of_transport: "train",
            dst_station: 2,
            dept_time: 10_000,
            arrival_time: 20_000
          }
        ],
        %Preference{day: 0}
      )

    # Mock register for mocking the NC
    MockRegister
    |> expect(:check_active, fn _ -> true end)

    dependency = %Dependency{
      station: MockStation,
      registry: MockRegister,
      collector: MockCollector,
      itinerary: Util.Itinerary
    }

    # New Fsm
    station_fsm = FSM.initialise_fsm([station_state, dependency])

    station_fsm =
      station_fsm
      |> FSM.query_input(itinerary)
      |> FSM.check_query_status()

    # Assertion on state
    assert FSM.state(station_fsm) == :ready
  end

  # Test 7

  # Check that if query is completed, it is sent to the appropriate
  # query collector
  test "Send completed query to station in 'query_rcvd' state" do
    # Station is the final station of the query
    station_state = %StationStruct{
      loc_vars: %{delay: 0.38, congestion: "low", disturbance: "no"},
      schedule: [
        %Connection{
          vehicleID: "100",
          src_station: 1,
          mode_of_transport: "bus",
          dst_station: 0,
          dept_time: 25_000,
          arrival_time: 35_000
        }
      ],
      station_number: 1,
      congestion_low: 4,
      choose_fn: 1
    }

    # Query which ends at current station
    itinerary =
      Itinerary.new(
        %Query{qid: "0300", src_station: 0, dst_station: 1, arrival_time: 0},
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
      itinerary: Util.Itinerary
    }

    # Mock register for mocking the NC
    MockRegister
    |> expect(:check_active, fn _ -> true end)

    # Mock collector for mocking the QC
    MockCollector
    |> expect(:collect, fn _ -> send(test_proc, :collected) end)

    # New Fsm
    station_fsm = FSM.initialise_fsm([station_state, dependency])

    station_fsm =
      station_fsm
      |> FSM.query_input(itinerary)
      |> FSM.check_query_status()

    # Assertion on state
    assert FSM.state(station_fsm) == :ready
    assert_receive :collected
  end

  # Test 8

  # If a valid, in-process query is sent to station, it transitions to
  # the 'process_query' state

  test "Send in-process, valid query to station in 'query_rcvd' state" do
    # Station variables
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

    # Itinerary which is not complete or invalid yet
    itinerary =
      Itinerary.new(
        %Query{qid: "0300", src_station: 0, dst_station: 2, arrival_time: 0},
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

    # Mock register to mock NC
    MockRegister
    |> expect(:check_active, fn _ -> true end)

    dependency = %Dependency{
      station: MockStation,
      registry: MockRegister,
      collector: MockCollector,
      itinerary: Util.Itinerary
    }

    # New Fsm
    station_fsm = FSM.initialise_fsm([station_state, dependency])

    station_fsm =
      station_fsm
      |> FSM.query_input(itinerary)
      |> FSM.check_query_status()

    # Assertion on state
    assert FSM.state(station_fsm) == :process_query
  end

  test "Check if itinerary is computed correctly" do
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
        },
        %Connection{
          vehicleID: "100",
          src_station: 1,
          mode_of_transport: "bus",
          dst_station: 4,
          dept_time: 24_000,
          arrival_time: 36_000
        }
      ],
      station_number: 1,
      congestion_low: 4,
      choose_fn: 1
    }

    # Itinerary
    itinerary =
      Itinerary.new(
        %Query{
          qid: "0300",
          src_station: 0,
          dst_station: 2,
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

    # Mock register to mock the NC
    MockRegister
    |> expect(:check_active, fn _ -> true end)
    |> expect(:lookup_code, fn _ -> true end)
    |> expect(:lookup_code, fn _ -> true end)

    MockStation
    |> expect(:send_query, 2, fn _, _ ->
      send(test_proc, :sent_to_neighbour)
    end)

    dependency = %Dependency{
      station: MockStation,
      registry: MockRegister,
      collector: MockCollector,
      itinerary: Util.Itinerary
    }

    # new Fsm
    station_fsm = FSM.initialise_fsm([station_state, dependency])

    station_fsm = FSM.process_itinerary(station_fsm, itinerary)

    assert FSM.state(station_fsm) == :ready
    assert_receive :sent_to_neighbour
  end
end
