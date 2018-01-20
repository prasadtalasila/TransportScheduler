defmodule StationFsmTest do
	@moduledoc"""
	Test suite for the StationFsm module
	"""

	use ExUnit.Case, async: true
	import Mox

	setup_all do
		Mox.defmock(MockCollectorFsm, for: TS.Collector)
		Mox.defmock(MockRegisterFsm, for: TS.Registry)
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
		station_vars = %StationStruct{}
		station_fsm = StationFsm.new |>
			StationFsm.input_data(station_vars, MockRegisterFsm, MockCollectorFsm)

		curr_state = StationFsm.state(station_fsm)
		curr_data = StationFsm.data(station_fsm)

		assert curr_state == :ready
		assert curr_data == [station_vars, MockRegisterFsm, MockCollectorFsm]
	end

	# Test 3

	# Check if update of variables takes place when in 'ready' state
	# and the new variables take the place of the old station variables

	test "Update variables in 'ready' state" do
		# Old variables
		station_vars = %StationStruct{}

		# New variables
		new_vars = %StationStruct{loc_vars: %{"delay": 0.12,
			"congestion": "low", "disturbance": "no"},
			schedule: [], station_number: 1710,
			station_name: "Mumbai", congestion_low: 3, choose_fn: 2}

		# New FSM
		station_fsm = StationFsm.new |>
			StationFsm.input_data(station_vars, MockRegisterFsm, MockCollectorFsm) |>
			StationFsm.update(new_vars)

		# Check if state is still ready
		assert StationFsm.state(station_fsm) == :ready

		# Assert conditions on data
		new_station_vars = Enum.at(StationFsm.data(station_fsm), 0)

		assert new_station_vars.loc_vars.delay == 0.12
		assert new_station_vars.schedule == []
		assert new_station_vars.station_number == 1710
		assert new_station_vars.station_name == "Mumbai"
	end

	# Test 4

	# Check if FSM transitions from 'ready' state to 'query_rcvd' state
	# when given a query as an input

	test "Receive query in 'ready' state" do
		# Itinerary which is received
		itinerary = [%{qid: "0300", src_station: 0, dst_station: 3, day: 0, arrival_time: 0},
		%{vehicleID: "99", src_station: 0, mode_of_transport: "train",
		dst_station: 1, dept_time: 10_000, arrival_time: 20_000}]

		station_vars = %StationStruct{}

		# New FSM
		station_fsm = StationFsm.new |>
			StationFsm.input_data(station_vars, MockRegisterFsm, MockCollectorFsm) |>
			StationFsm.query_input(itinerary)

		# Assertion on state
		assert StationFsm.state(station_fsm) == :query_rcvd

		# Assertions on data
		vars = StationFsm.data(station_fsm)

		assert Enum.at(vars, 0) == station_vars
		assert Enum.at(vars, 1) == MockRegisterFsm
		assert Enum.at(vars, 2) == MockCollectorFsm
		assert Enum.at(vars, 3) == itinerary
	end

	# Test 5

	# Check if queries with self-loops are handled correctly in
	# check_query_status function of the 'query_rcvd' state

	test "Check status of query with self-loop in 'query_rcvd' state" do
		station_vars = %StationStruct{loc_vars: %{"delay": 0.38,
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
		station_fsm = StationFsm.new |>
			StationFsm.input_data(station_vars, MockRegisterFsm, MockCollectorFsm) |>
			StationFsm.query_input(itinerary) |>
			StationFsm.check_query_status

		# Check if the function has classified query as invalid
		assert Enum.at(StationFsm.data(station_fsm), 3) == :invalid

		# Assertion on state
		assert StationFsm.state(station_fsm) == :ready
	end

	# Test 6

	# Check if a query with the wrong destination station is handled
	# correctly by the FSM

	test "Check status of query with wrong dst in 'query_rcvd' state" do
		# station_number of the station is set to 1
		station_vars = %StationStruct{loc_vars: %{"delay": 0.38,
			"congestion": "low", "disturbance": "no"},
			schedule: [%{vehicleID: "100", src_station: 1, mode_of_transport: "bus",
			dst_station: 0, dept_time: 25_000, arrival_time: 35_000}],
			station_number: 1, congestion_low: 4, choose_fn: 1}

		# Query with different dst_station
		itinerary = [%{qid: "0300", src_station: 0, dst_station: 3, day: 0, arrival_time: 0},
			%{vehicleID: "99", src_station: 0, mode_of_transport: "train",
			dst_station: 2, dept_time: 10_000, arrival_time: 20_000}]

		# Mock register for mocking the NC
		MockRegisterFsm
		|> expect(:check_active, fn(_) -> true end)

		# New FSM
		station_fsm = StationFsm.new |>
			StationFsm.input_data(station_vars, MockRegisterFsm, MockCollectorFsm) |>
			StationFsm.update(station_vars) |>
			StationFsm.query_input(itinerary) |>
			StationFsm.check_query_status

		# Assertion on state
		assert StationFsm.state(station_fsm) == :ready

		# Check if function has returned :invalid
		assert Enum.at(StationFsm.data(station_fsm), 3) == :invalid
	end

	# Test 7

	# Check that if query is completed, it is sent to the appropriate
	# query collector

	test "Send completed query to station in 'query_rcvd' state" do
		# Station is the final station of the query
		station_vars = %StationStruct{loc_vars: %{"delay": 0.38,
			"congestion": "low", "disturbance": "no"},
			schedule: [%{vehicleID: "100", src_station: 1, mode_of_transport: "bus",
			dst_station: 0, dept_time: 25_000, arrival_time: 35_000}],
			station_number: 1, congestion_low: 4, choose_fn: 1}

		# Query which ends at current station
		itinerary = [%{qid: "0300", src_station: 0, dst_station: 1, day: 0, arrival_time: 0},
			%{vehicleID: "99", src_station: 0, mode_of_transport: "train",
			dst_station: 1, dept_time: 10_000, arrival_time: 20_000}]

		# Mock register for mocking the NC
		MockRegisterFsm
		|> expect(:check_active, fn(_) -> true end)

		# Mock collector for mocking the QC
		MockCollectorFsm
		|> expect(:collect, fn(_) -> true end)

		# New FSM
		station_fsm = StationFsm.new |>
			StationFsm.input_data(station_vars, MockRegisterFsm, MockCollectorFsm) |>
			StationFsm.query_input(itinerary) |>
			StationFsm.check_query_status

		# Assertion on state
		assert StationFsm.state(station_fsm) == :ready

		# Check if function has returned :collect
		assert Enum.at(StationFsm.data(station_fsm), 3) == :collect
	end

	# Test 8

	# If a valid, in-process query is sent to station, it transitions to
	# the 'query_init' state

	test "Send in-process, valid query to station in 'query_rcvd' state" do
		# Station variables
		station_vars = %StationStruct{loc_vars: %{"delay": 0.38,
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
		station_fsm = StationFsm.new |>
			StationFsm.input_data(station_vars, MockRegisterFsm, MockCollectorFsm) |>
			StationFsm.query_input(itinerary) |>
			StationFsm.check_query_status

		# Check if function returns :valid
		assert Enum.at(StationFsm.data(station_fsm), 4) == :valid

		# Assertion on state
		assert StationFsm.state(station_fsm) == :query_init
	end

	# Test 9

	# Check if the neighbours_fulfilment array is initialized in
	# an appropriate manner

	test "Initialize neighbours_fulfilment array" do
		# Station vars -> schedule contains 2 and 4 as neighbouring
		# dst_stations. These should be initialized in the neighbours map
		station_vars = %StationStruct{loc_vars: %{"delay": 0.38,
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
		station_fsm = StationFsm.new |>
			StationFsm.input_data(station_vars, MockRegisterFsm, MockCollectorFsm) |>
			StationFsm.query_input(itinerary) |>
			StationFsm.check_query_status |>
			StationFsm.initialize

		# Assertion on state
		assert StationFsm.state(station_fsm) == :query_fulfilment_check

		# Getting the neighbours map
		added_element = Enum.at(StationFsm.data(station_fsm), 0)
		nbrsmap = elem(added_element, 0)

		# Assertions on the neighbours map
		assert Kernel.map_size(nbrsmap) == 2
		assert nbrsmap[2] == 0
		assert nbrsmap[4] == 0
		assert nbrsmap[3] == nil
	end

	# Test 10

	# Check if stop_dn works properly by calling check_stop in 'query_fulfilment_check'

	test "Check stop_fn" do
		station_vars = %StationStruct{loc_vars: %{"delay": 0.38,
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
		station_fsm = StationFsm.new |>
			StationFsm.input_data(station_vars, MockRegisterFsm, MockCollectorFsm) |>
			StationFsm.query_input(itinerary) |>
			StationFsm.check_query_status |>
			StationFsm.initialize |>
			StationFsm.check_stop

		assert StationFsm.state(station_fsm) == :compute_itinerary
	end

	# Test 11

	# Call check_stop repeatedly to see if the itinerary is computed
	# as needed

	test "Check if itinerary is computed correctly" do
		station_vars = %StationStruct{loc_vars: %{"delay": 0.38,
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

		# Mock register to mock the NC
		MockRegisterFsm
		|> expect(:check_active, fn(_) -> true end)
		|> expect(:lookup_code, fn(_) -> true end)
		|> expect(:lookup_code, fn(_) -> true end)


		# Calling check_stop four times will create make all the
		# entries in the map as 1:
		# > %{2 => 0, 4 => 0}
		# > %{2 => 0, 4 => 1}
		# > %{2 => 1, 4 => 1}
		# The stop function will then return true and the station
		# will transition to 'ready' state
		station_fsm = StationFsm.new |>
			StationFsm.input_data(station_vars, MockRegisterFsm, MockCollectorFsm) |>
			StationFsm.query_input(itinerary) |>
			StationFsm.check_query_status |>
			StationFsm.initialize |>
			StationFsm.check_stop |>
			StationFsm.check_stop |>
			StationFsm.check_stop |>
			StationFsm.check_stop |>
			StationFsm.check_stop

		assert StationFsm.state(station_fsm) == :ready
	end

end
