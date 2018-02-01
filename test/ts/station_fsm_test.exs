defmodule StationFsmTest do
	@moduledoc"""
	Test suite for the StationFsm module
	"""

	use ExUnit.Case, async: true
	import Mox

	setup_all do
		Mox.defmock(MockCollectorFsm, for: TS.Collector)
		Mox.defmock(MockRegisterFsm, for: TS.Registry)
		Mox.defmock(MockStationFsm, for: TS.StationBehaviour)
		:ok
	end

	# Test 1

	# Check if initial state is 'start' and initial data
	# is an empty list

	test "Check configuration of initial state" do
		# Create new station and query for state and data
		station_fsm = StationFsm.new

		initial_state = StationFsm.state(station_fsm)
		initial_data = StationFsm.data(station_fsm)

		assert initial_state == :start
		assert initial_data == []
	end

	# Test 2

	# Check if given parameters are taken as input by the FSM when
	# transitioning from 'start' to 'ready' state

	test "Check transition from start to ready state on input data" do
		station_state = %StationStruct{loc_vars: %{"delay": 0.38,
			"congestion": "low", "disturbance": "no"},
			schedule: [%{vehicleID: "100", src_station: 1, mode_of_transport: "bus",
			dst_station: 2, dept_time: 25_000, arrival_time: 35_000}], station_number: 1,
			congestion_low: 4, choose_fn: 1}

		# Create new station and query for state and data
		station_fsm = StationFsm.initialise_fsm([station_state ,
		{MockRegisterFsm, MockCollectorFsm, MockStationFsm}])

		assert StationFsm.state(station_fsm) == :ready
		assert StationFsm.data(station_fsm) == [station_state, {MockRegisterFsm, MockCollectorFsm, MockStationFsm}]
	end

	# Test 3

	# Check if update of variables takes place when in 'ready' state
	# and the new variables take the place of the old station variables

	test "Update variables in 'ready' state" do
		station_state = %StationStruct{loc_vars: %{"delay": 0.38,
			"congestion": "low", "disturbance": "no"},
			schedule: [%{vehicleID: "100", src_station: 1, mode_of_transport: "bus",
			dst_station: 2, dept_time: 25_000, arrival_time: 35_000}], station_number: 1,
			congestion_low: 4, choose_fn: 1}

		# Create new station and query for state and data
		station_fsm = StationFsm.initialise_fsm([station_state ,
		{MockRegisterFsm, MockCollectorFsm, MockStationFsm}])

		# Update Station State to new value
		station_state = %{station_state | schedule: []}
		station_fsm = StationFsm.update(station_fsm, station_state)

		assert StationFsm.state(station_fsm) == :ready
		assert StationFsm.data(station_fsm) == [station_state, {MockRegisterFsm, MockCollectorFsm, MockStationFsm}]
	end

	# Test 4

	# Check if FSM transitions from 'ready' state to 'query_rcvd' state
	# when given a query as an input

	test "Receive query in 'ready' state" do
		# Itinerary which is received
		itinerary = [%{qid: "0300", src_station: 0, dst_station: 3, day: 0, arrival_time: 0},
		%{vehicleID: "99", src_station: 0, mode_of_transport: "train",
		dst_station: 1, dept_time: 10_000, arrival_time: 20_000}]

		station_state = %StationStruct{loc_vars: %{"delay": 0.38,
			"congestion": "low", "disturbance": "no"},
			schedule: [%{vehicleID: "100", src_station: 1, mode_of_transport: "bus",
			dst_station: 2, dept_time: 25_000, arrival_time: 35_000}], station_number: 1,
			congestion_low: 4, choose_fn: 1}

		# New FSM
		station_fsm = StationFsm.initialise_fsm([station_state ,
		{MockRegisterFsm, MockCollectorFsm, MockStationFsm}])

		station_fsm = StationFsm.query_input(station_fsm, itinerary)

		# Assertion on state
		assert StationFsm.state(station_fsm) == :query_rcvd

		# Assertions on data
		assert StationFsm.data(station_fsm) == [itinerary, station_state ,
		{MockRegisterFsm, MockCollectorFsm, MockStationFsm}]
	end

	# Test 5
	# check_query_status function of the 'query_rcvd' state on query with self loops

	test "Check status of query with self-loop in 'query_rcvd' state" do
		station_state = %StationStruct{loc_vars: %{"delay": 0.38,
			"congestion": "low", "disturbance": "no"},
			schedule: [%{vehicleID: "100", src_station: 2, mode_of_transport: "bus",
			dst_station: 0, dept_time: 25_000, arrival_time: 35_000}],
			station_number: 2, congestion_low: 4, choose_fn: 1}

		itinerary = [%{qid: "0300", src_station: 0, dst_station: 7, day: 0, arrival_time: 0},
			%{vehicleID: "99", src_station: 0, mode_of_transport: "train",
			dst_station: 1, dept_time: 10_000, arrival_time: 20_000},
			%{vehicleID: "100", src_station: 1, mode_of_transport: "train",
			dst_station: 2, dept_time: 20_000, arrival_time: 25_000},
			%{vehicleID: "101", src_station: 2, mode_of_transport: "train",
			dst_station: 3, dept_time: 25_000, arrival_time: 27_000}]

		# Mock register for mocking the NC
		MockRegisterFsm
		|> expect(:check_active, fn(_) -> true end)

		# New FSM
		# New FSM
		station_fsm = StationFsm.initialise_fsm([station_state ,
		{MockRegisterFsm, MockCollectorFsm, MockStationFsm}])

		station_fsm = station_fsm |>
			StationFsm.query_input(itinerary) |>
			StationFsm.check_query_status

		# Assertion on state
		assert StationFsm.state(station_fsm) == :ready
	end

	# Test 6

	# Check if a query with the wrong destination station is handled
	# correctly by the FSM

	test "Check status of query with wrong dst in 'query_rcvd' state" do
		# station_number of the station is set to 1
		station_state = %StationStruct{loc_vars: %{"delay": 0.38,
			"congestion": "low", "disturbance": "no"},
			schedule: [%{vehicleID: "100", src_station: 1, mode_of_transport: "bus",
			dst_station: 0, dept_time: 25_000, arrival_time: 35_000}],
			station_number: 1, congestion_low: 4, choose_fn: 1}

		# Query with different dst_station
		itinerary = [%{qid: "0300", src_station: 0, dst_station: 3, day: 0, arrival_time: 0},
			%{vehicleID: "99", src_station: 0, mode_of_transport: "train",
			dst_station: 2, dept_time: 10_000, arrival_time: 20_000}]

		# Mock register for mocking the NC
		# Mock register for mocking the NC
		MockRegisterFsm
		|> expect(:check_active, fn(_) -> true end)

		# New FSM
		station_fsm = StationFsm.initialise_fsm([station_state ,
		{MockRegisterFsm, MockCollectorFsm, MockStationFsm}])

		station_fsm = station_fsm |>
			StationFsm.query_input(itinerary) |>
			StationFsm.check_query_status

		# Assertion on state
		assert StationFsm.state(station_fsm) == :ready
	end

	# Test 7

	# Check that if query is completed, it is sent to the appropriate
	# query collector

	test "Send completed query to station in 'query_rcvd' state" do
		# Station is the final station of the query
		station_state = %StationStruct{loc_vars: %{"delay": 0.38,
			"congestion": "low", "disturbance": "no"},
			schedule: [%{vehicleID: "100", src_station: 1, mode_of_transport: "bus",
			dst_station: 0, dept_time: 25_000, arrival_time: 35_000}],
			station_number: 1, congestion_low: 4, choose_fn: 1}

		# Query which ends at current station
		itinerary = [%{qid: "0300", src_station: 0, dst_station: 1, day: 0, arrival_time: 0},
			%{vehicleID: "99", src_station: 0, mode_of_transport: "train",
			dst_station: 1, dept_time: 10_000, arrival_time: 20_000}]


		test_proc = self()
		# Mock register for mocking the NC
		MockRegisterFsm
		|> expect(:check_active, fn(_) -> true end)

		# Mock collector for mocking the QC
		MockCollectorFsm
		|> expect(:collect, fn(_) -> send(test_proc, :collected) end)

		# New FSM
		# New FSM
		station_fsm = StationFsm.initialise_fsm([station_state ,
		{MockRegisterFsm, MockCollectorFsm, MockStationFsm}])

		station_fsm = station_fsm |>
			StationFsm.query_input(itinerary) |>
			StationFsm.check_query_status

		# Assertion on state
		assert StationFsm.state(station_fsm) == :ready
		assert_receive :collected

	end

	# Test 8

	# If a valid, in-process query is sent to station, it transitions to
	# the 'query_init' state

	test "Send in-process, valid query to station in 'query_rcvd' state" do
		# Station variables
		station_state = %StationStruct{loc_vars: %{"delay": 0.38,
			"congestion": "low", "disturbance": "no"},
			schedule: [%{vehicleID: "100", src_station: 1, mode_of_transport: "bus",
			dst_station: 2, dept_time: 25_000, arrival_time: 35_000}],
			station_number: 1, congestion_low: 4, choose_fn: 1}

		# Itinerary which is not complete or invalid yet
		itinerary = [%{qid: "0300", src_station: 0, dst_station: 3, day: 0, arrival_time: 0},
			%{vehicleID: "99", src_station: 0, mode_of_transport: "train",
			dst_station: 1, dept_time: 10_000, arrival_time: 20_000}]

		# Mock register to mock NC
		MockRegisterFsm
		|> expect(:check_active, fn(_) -> true end)

		# New FSM
		station_fsm = StationFsm.initialise_fsm([station_state ,
		{MockRegisterFsm, MockCollectorFsm, MockStationFsm}])

		station_fsm = station_fsm |>
			StationFsm.query_input(itinerary) |>
			StationFsm.check_query_status

		# Assertion on state
		assert StationFsm.state(station_fsm) == :query_init
	end

	# Test 9

	# Check if the neighbours_fulfilment array is initialized in
	# an appropriate manner

	test "Initialize neighbours_fulfilment array" do
		# Station vars -> schedule contains 2 and 4 as neighbouring
		# dst_stations. These should be initialized in the neighbours map
		station_state = %StationStruct{loc_vars: %{"delay": 0.38,
			"congestion": "low", "disturbance": "no"},
			schedule: [%{vehicleID: "100", src_station: 1, mode_of_transport: "bus",
			dst_station: 2, dept_time: 25_000, arrival_time: 35_000},
			%{vehicleID: "100", src_station: 1, mode_of_transport: "bus",
			dst_station: 4, dept_time: 24_000, arrival_time: 36_000}],
			station_number: 1, congestion_low: 4, choose_fn: 1}

		# Itinerary
		itinerary = [%{qid: "0300", src_station: 0, dst_station: 3, day: 0, arrival_time: 0},
			%{vehicleID: "99", src_station: 0, mode_of_transport: "train",
			dst_station: 1, dept_time: 10_000, arrival_time: 20_000}]

		# Mock register to mock the NC
		MockRegisterFsm
		|> expect(:check_active, fn(_) -> true end)

		# New FSM
		# Mock register to mock NC
		MockRegisterFsm
		|> expect(:check_active, fn(_) -> true end)

		# New FSM
		station_fsm = StationFsm.initialise_fsm([station_state ,
		{MockRegisterFsm, MockCollectorFsm, MockStationFsm}])

		station_fsm = station_fsm |>
			StationFsm.query_input(itinerary) |>
			StationFsm.check_query_status |>
			StationFsm.initialise

		# Assertion on state
		assert StationFsm.state(station_fsm) == :query_fulfilment_check

		# Getting the neighbours map
		[working_state | _] = StationFsm.data(station_fsm)
		neighbour_map = elem(working_state, 0)

		# Assertions on the neighbours map
		assert Kernel.map_size(neighbour_map) == 2
		assert neighbour_map[2] == 0
		assert neighbour_map[4] == 0
		assert neighbour_map[3] == nil
	end

	# Test 10

	# Check if stop_dn works properly by calling check_stop in 'query_fulfilment_check'

	test "Check stop_fn" do
		station_state = %StationStruct{loc_vars: %{"delay": 0.38,
			"congestion": "low", "disturbance": "no"},
			schedule: [%{vehicleID: "100", src_station: 1, mode_of_transport: "bus",
			dst_station: 2, dept_time: 25_000, arrival_time: 35_000},
			%{vehicleID: "100", src_station: 1, mode_of_transport: "bus",
			dst_station: 4, dept_time: 24_000, arrival_time: 36_000}],
			station_number: 1, congestion_low: 4, choose_fn: 1}

		# Itinerary
		itinerary = [%{qid: "0300", src_station: 0, dst_station: 3, day: 0, arrival_time: 0},
			%{vehicleID: "99", src_station: 0, mode_of_transport: "train",
			dst_station: 1, dept_time: 10_000, arrival_time: 20_000}]

		# Mock register to mock the NC
		MockRegisterFsm
		|> expect(:check_active, fn(_) -> true end)


		# new FSM
		station_fsm = StationFsm.initialise_fsm([station_state ,
		{MockRegisterFsm, MockCollectorFsm, MockStationFsm}])

		station_fsm = station_fsm |>
			StationFsm.query_input(itinerary) |>
			StationFsm.check_query_status |>
			StationFsm.initialise |>
			StationFsm.check_stop

		assert StationFsm.state(station_fsm) == :compute_itinerary
	end

	# Test 11

	# Call check_stop repeatedly to see if the itinerary is computed
	# as needed

	test "Check if itinerary is computed correctly" do
		station_state = %StationStruct{loc_vars: %{"delay": 0.38,
			"congestion": "low", "disturbance": "no"},
			schedule: [%{vehicleID: "100", src_station: 1, mode_of_transport: "bus",
			dst_station: 2, dept_time: 25_000, arrival_time: 35_000},
			%{vehicleID: "100", src_station: 1, mode_of_transport: "bus",
			dst_station: 4, dept_time: 24_000, arrival_time: 36_000}],
			station_number: 1, congestion_low: 4, choose_fn: 1}

		# Itinerary
		itinerary = [%{qid: "0300", src_station: 0, dst_station: 3, day: 0, arrival_time: 0, end_time: 999_999},
			%{vehicleID: "99", src_station: 0, mode_of_transport: "train",
			dst_station: 1, dept_time: 10_000, arrival_time: 20_000}]

		test_proc = self()

		# Mock register to mock the NC
		MockRegisterFsm
		|> expect(:check_active, fn(_) -> true end)
		|> expect(:lookup_code, fn(_) -> true end)
		|> expect(:lookup_code, fn(_) -> true end)

		MockStationFsm
		|> expect(:send_query, 2, fn(_, _) -> send(test_proc, :sent_to_neighbour) end)


		# new FSM
		station_fsm = StationFsm.initialise_fsm([station_state ,
		{MockRegisterFsm, MockCollectorFsm, MockStationFsm}])

		station_fsm = StationFsm.process_itinerary(station_fsm, itinerary)

		assert StationFsm.state(station_fsm) == :ready
		assert_receive :sent_to_neighbour
	end

end
