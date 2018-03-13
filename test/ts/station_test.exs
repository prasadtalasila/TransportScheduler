defmodule StationTest do
	@moduledoc"""
	Module to test Station.
	Create new station process with associated FSM and updates local variable
	values. It also tests the interaction of one station with the others.
	It also tests the validity of a query and the interaction of the Station
	with the Query Collector.
	"""

	# set async:true in test servers for concurrent tests
	use ExUnit.Case, async: true
	import Mox
	alias Station.Registry, as: Registry
	alias Station.Collector, as: Collector
	alias Station.StationBehaviour, as: StationBehaviour
	alias Util.Dependency, as: Dependency
	alias Util.Itinerary, as: Itinerary
	alias Util.Query, as: Query
	alias Util.Connection, as: Connection
	alias Util.Preference, as: Preference
	alias Util.StationStruct, as: StationStruct

	setup_all do
		Mox.defmock(MockCollector, for: Collector)
		Mox.defmock(MockRegister, for: Registry)
		Mox.defmock(MockStation, for: StationBehaviour)
		:ok
	end

	# Test 1

	# Test to see if data can be retrieved from the station correctly
	test "retrieving the given schedule" do

		# Station Schedule
		schedule = [%Connection{vehicleID: "100", src_station: 1,
		mode_of_transport: "bus", dst_station: 2, dept_time: 25_000,
		arrival_time: 35_000}]

		station_state = %StationStruct{loc_vars: %{"delay": 0.12,
			"congestion": "low", "disturbance": "no"},
			schedule: schedule, station_number: 1710,
			station_name: "Mumbai", congestion_low: 3, choose_fn: 2}

		# Start the server
		dependency = %Dependency{station: MockStation,
		registry: MockRegister,
		collector: MockCollector,
		itinerary: Itinerary}

		{:ok, pid} = start_supervised({Station, [station_state, dependency]})

		# Retrieve Time Table
		assert Station.get_timetable(pid) == schedule

	end

	# Test 2
	# Test to see if the station schedule can be updated
	test "updating the station schedule" do

		# Station Schedule
		schedule = [%Connection{vehicleID: "100", src_station: 1,
		mode_of_transport: "bus", dst_station: 2, dept_time: 25_000,
		arrival_time: 35_000}]

		new_schedule = [%Connection{vehicleID: "88", src_station: 1,
		mode_of_transport: "train", dst_station: 2, dept_time: 12_000,
		arrival_time: 24_000},
		%Connection{vehicleID: "100", src_station: 1, mode_of_transport: "bus",
		dst_station: 2, dept_time: 25_000, arrival_time: 35_000}]

		station_state = %StationStruct{loc_vars: %{"delay": 0.12,
			"congestion": "low", "disturbance": "no"},
			schedule: schedule, station_number: 1710,
			station_name: "Mumbai", congestion_low: 3, choose_fn: 2}

		dependency = %Dependency{station: MockStation,
		registry: MockRegister,
		collector: MockCollector,
		itinerary: Itinerary}

		# Start the server
		{:ok, pid} = start_supervised({Station, [station_state,
		dependency]})

		new_station_state = %{station_state | schedule: new_schedule}

		Station.update(pid, new_station_state)

		# Retrieve the Time Table and check if it has been updated
		assert Station.get_timetable(pid) == new_schedule

	end

	# Test 3
	test "Receive a itinerary search query" do

		# Set function parameters to arbitrary values.
		# effect only after the station has received the query.
		query = Itinerary.new(%Query{qid: "0300", src_station: 0, dst_station: 3,
		arrival_time: 0, end_time: 999_999}, %Preference{day: 0})
		# Any errors due to invalid values do not matter as they will come into

		station_state = %StationStruct{loc_vars: %{"delay": 0.38,
			"congestion": "low", "disturbance": "no"},
			schedule: [%Connection{vehicleID: "100", src_station: 1,
			mode_of_transport: "bus",
			dst_station: 2, dept_time: 25_000, arrival_time: 35_000}],
			station_number: 1,
			congestion_low: 4, choose_fn: 1}

		test_proc = self()

		# Create NetworkConstructor Mock
		MockRegister
		|> expect(:check_active, fn(_) -> send(test_proc, :query_received)
			false
			end)

		dependency = %Dependency{station: MockStation,
		registry: MockRegister,
		collector: MockCollector,
		itinerary: Itinerary}

		# start station
		{:ok, pid} = Station.start_link [station_state,
		dependency]

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

	# Test 4
	test "Send completed search query to neighbours" do
		station_state = %StationStruct{loc_vars: %{"delay": 0.38,
			"congestion": "low", "disturbance": "no"},
			schedule: [%Connection{vehicleID: "100", src_station: 1,
			mode_of_transport: "bus",
			dst_station: 2, dept_time: 25_000, arrival_time: 35_000}],
			station_number: 1,
			congestion_low: 4, choose_fn: 1}

		# Station state of Neighbour : %StationStruct{loc_vars: %{"delay": 0.38,
		# 	"congestion": "low", "disturbance": "no"},
		# 	schedule: [], congestion_low: 4, choose_fn: 1}

		itinerary = Itinerary.new(%Query{qid: "0300", src_station: 0,
		dst_station: 3, arrival_time: 0, end_time: 999_999},
		[%Connection{vehicleID: "99", src_station: 0, mode_of_transport: "train",
		dst_station: 1, dept_time: 10_000, arrival_time: 20_000}],
		%Preference{day: 0})

		test_proc = self()

		dependency = %Dependency{station: MockStation,
		registry: MockRegister,
		collector: MockCollector,
		itinerary: Itinerary}

		{:ok, pid} = Station.start_link [station_state,
		dependency]

		# Define the expectation for the Mock of the Network Constructor
		MockRegister
		|> expect(:lookup_code, fn(_) -> test_proc end)
		|> expect(:check_active, fn(_) -> true end)

		MockStation
		|> expect(:send_query, fn(^test_proc, _) ->
			send(test_proc, :query_forwarded) end)

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

	# Test 5
	test "Does not forward stale queries" do
		station_state = %StationStruct{loc_vars: %{"delay": 0.38,
			"congestion": "low", "disturbance": "no"},
			schedule: [%Connection{vehicleID: "100", src_station: 1,
			mode_of_transport: "bus",
			dst_station: 2, dept_time: 25_000, arrival_time: 35_000}],
			station_number: 1,
			congestion_low: 4, choose_fn: 1}

		# Station state of Neighbour : %StationStruct{loc_vars: %{"delay": 0.38,
		# 	"congestion": "low", "disturbance": "no"},
		# 	schedule: [], congestion_low: 4, choose_fn: 1}

		itinerary = Itinerary.new(%Query{qid: "0300", src_station: 0,
		dst_station: 3, arrival_time: 0, end_time: 999_999},
		[%Connection{vehicleID: "99", src_station: 0, mode_of_transport: "train",
		dst_station: 1, dept_time: 10_000, arrival_time: 20_000}],
		%Preference{day: 0})

		test_proc = self()

		dependency = %Dependency{station: MockStation,
		registry: MockRegister,
		collector: MockCollector,
		itinerary: Itinerary}

		{:ok, pid} = Station.start_link [station_state,
		dependency]

		# Define the expectation for the Mock of the Network Constructor
		MockRegister
		|> expect(:lookup_code, fn(_) -> test_proc end)
		|> expect(:check_active, fn(_) -> false end)

		MockStation
		|> expect(:send_query, fn(_, _) ->
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

	# Test 6
	test "Does not forward queries with self loops" do
		station_state = %StationStruct{loc_vars: %{"delay": 0.38,
			"congestion": "low", "disturbance": "no"},
			schedule: [%Connection{vehicleID: "100", src_station: 1,
			mode_of_transport: "bus",
			dst_station: 2, dept_time: 25_000, arrival_time: 35_000}],
			station_number: 1,
			congestion_low: 4, choose_fn: 1}

		# Station state of Neighbour : %StationStruct{loc_vars: %{"delay": 0.38,
		# 	"congestion": "low", "disturbance": "no"},
		# 	schedule: [], congestion_low: 4, choose_fn: 1}

		itinerary = Itinerary.new(%Query{qid: "0300", src_station: 1,
			dst_station: 3, arrival_time: 0, end_time: 999_999},
			[%Connection{vehicleID: "100", src_station: 2, mode_of_transport: "train",
			dst_station: 1, dept_time: 25_000, arrival_time: 30_000},
			%Connection{vehicleID: "99", src_station: 1, mode_of_transport: "train",
			dst_station: 2, dept_time: 10_000, arrival_time: 20_000}],
			%Preference{day: 0})

		test_proc = self()

		dependency = %Dependency{station: MockStation,
		registry: MockRegister,
		collector: MockCollector,
		itinerary: Itinerary}

		{:ok, pid} = Station.start_link [station_state,
		dependency]

		# Define the expectation for the Mock of the Network Constructor
		MockRegister
		|> expect(:lookup_code, fn(_) -> test_proc end)
		|> expect(:check_active, fn(_) -> true end)

		MockStation
		|> expect(:send_query, fn(_, _) ->
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

	# Test 7
	test "Incorrectly received queries are discarded" do
		station_state = %StationStruct{loc_vars: %{"delay": 0.38,
			"congestion": "low", "disturbance": "no"},
			schedule: [%Connection{vehicleID: "100", src_station: 1,
			mode_of_transport: "bus",
			dst_station: 2, dept_time: 25_000, arrival_time: 35_000}],
			station_number: 1,
			congestion_low: 4, choose_fn: 1}

		# Station state of Neighbour : %StationStruct{loc_vars: %{"delay": 0.38,
		# 	"congestion": "low", "disturbance": "no"},
		# 	schedule: [], congestion_low: 4, choose_fn: 1}

		itinerary = Itinerary.new(%Query{qid: "0300", src_station: 1,
			dst_station: 3, arrival_time: 0, end_time: 999_999},
			[%Connection{vehicleID: "99", src_station: 1, mode_of_transport: "train",
			dst_station: 11, dept_time: 10_000, arrival_time: 20_000}],
			%Preference{day: 0})

		test_proc = self()

		dependency = %Dependency{station: MockStation,
		registry: MockRegister,
		collector: MockCollector,
		itinerary: Itinerary}

		{:ok, pid} = Station.start_link [station_state,
		dependency]

		# Define the expectation for the Mock of the Network Constructor
		MockRegister
		|> expect(:lookup_code, fn(_) -> test_proc end)
		|> expect(:check_active, fn(_) -> true end)

		MockStation
		|> expect(:send_query, fn(_, _) ->
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

	# Test 8
	test "No query is forwarded from a Station with no viable paths
	(no viable neighbouring station)." do
		station_state = %StationStruct{loc_vars: %{"delay": 0.38,
			"congestion": "low", "disturbance": "no"},
			schedule: [%Connection{vehicleID: "100", src_station: 1,
			mode_of_transport: "bus",
			dst_station: 2, dept_time: 15_000, arrival_time: 35_000}],
			station_number: 1,
			congestion_low: 4, choose_fn: 1}

		# Station state of Neighbour : %StationStruct{loc_vars: %{"delay": 0.38,
		# 	"congestion": "low", "disturbance": "no"},
		# 	schedule: [], congestion_low: 4, choose_fn: 1}

		itinerary = Itinerary.new(%Query{qid: "0300", src_station: 0,
		dst_station: 3, arrival_time: 0, end_time: 25_000},
			[%Connection{vehicleID: "99", src_station: 0, mode_of_transport: "train",
			dst_station: 1, dept_time: 10_000, arrival_time: 20_000}],
			%Preference{day: 0})

		test_proc = self()

		dependency = %Dependency{station: MockStation,
		registry: MockRegister,
		collector: MockCollector,
		itinerary: Itinerary}

		{:ok, pid} = Station.start_link [station_state,
		dependency]

		# Define the expectation for the Mock of the Network Constructor
		MockRegister
		|> expect(:lookup_code, fn(_) -> test_proc end)
		|> expect(:check_active, fn(_) -> true end)

		MockStation
		|> expect(:send_query, fn(_, _) ->
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

	# Test 9
	test "The correct itinerary is forwarded to the next station" do
		station_state = %StationStruct{loc_vars: %{"delay": 0.38,
			"congestion": "low", "disturbance": "no"},
			schedule: [%Connection{vehicleID: "100", src_station: 1,
			mode_of_transport: "bus",
			dst_station: 2, dept_time: 25_000, arrival_time: 35_000}],
			station_number: 1,
			congestion_low: 4, choose_fn: 1}

		# Station state of Neighbour : %StationStruct{loc_vars: %{"delay": 0.38,
		# 	"congestion": "low", "disturbance": "no"},
		# 	schedule: [], congestion_low: 4, choose_fn: 1}

		itinerary = Itinerary.new(%Query{qid: "0300", src_station: 0,
		dst_station: 3, arrival_time: 0, end_time: 999_999},
		[%Connection{vehicleID: "99", src_station: 0, mode_of_transport: "train",
			dst_station: 1, dept_time: 10_000, arrival_time: 20_000}],
			%Preference{day: 0})

		proper_itinerary = Itinerary.add_link(itinerary,
		%Connection{vehicleID: "100", src_station: 1, mode_of_transport: "bus",
		dst_station: 2, dept_time: 25_000, arrival_time: 35_000})

		test_proc = self()

		dependency = %Dependency{station: MockStation,
		registry: MockRegister,
		collector: MockCollector,
		itinerary: Itinerary}

		{:ok, pid} = Station.start_link [station_state,
		dependency]

		# Define the expectation for the Mock of the Network Constructor
		MockRegister
		|> expect(:lookup_code, fn(_) -> test_proc end)
		|> expect(:check_active, fn(_) -> true end)

		MockStation
		|> expect(:send_query, fn(^test_proc, itinerary) ->
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

	# Test 10
	test "Itinerary only for a single valid connection is forwarded to the next station" do
		station_state = %StationStruct{loc_vars: %{"delay": 0.38,
			"congestion": "low", "disturbance": "no"},
			schedule: [%Connection{vehicleID: "100", src_station: 1,
			 mode_of_transport: "bus",
			dst_station: 2, dept_time: 25_000, arrival_time: 35_000},
			%Connection{vehicleID: "103", src_station: 1, mode_of_transport: "bus",
			dst_station: 2, dept_time: 25_000, arrival_time: 35_000}],
			station_number: 1,
			congestion_low: 4, choose_fn: 1}

		# Station state of Neighbour : %StationStruct{loc_vars: %{"delay": 0.38,
		# 	"congestion": "low", "disturbance": "no"},
		# 	schedule: [], congestion_low: 4, choose_fn: 1}

		itinerary = Itinerary.new(%Query{qid: "0300", src_station: 0,
		dst_station: 3, arrival_time: 0, end_time: 999_999},
			[%Connection{vehicleID: "99", src_station: 0, mode_of_transport: "train",
			dst_station: 1, dept_time: 10_000, arrival_time: 20_000}],
			%Preference{day: 0})

		proper_itinerary = Itinerary.add_link(itinerary,
		%Connection{vehicleID: "100", src_station: 1, mode_of_transport: "bus",
		dst_station: 2, dept_time: 25_000, arrival_time: 35_000})

		improper_itinerary = Itinerary.add_link(itinerary,
		%Connection{vehicleID: "103", src_station: 1, mode_of_transport: "bus",
		dst_station: 2, dept_time: 25_000, arrival_time: 35_000})

		test_proc = self()

		dependency = %Dependency{station: MockStation,
		registry: MockRegister,
		collector: MockCollector,
		itinerary: Itinerary}

		{:ok, pid} = Station.start_link [station_state,
		dependency]

		# Define the expectation for the Mock of the Network Constructor
		MockRegister
		|> expect(:lookup_code, fn(_) -> test_proc end)
		|> expect(:check_active, fn(_) -> true end)

		MockStation
		|> expect(:send_query, 2 , fn(^test_proc, itinerary) ->
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
		refute_receive({:itinerary_received, ^improper_itinerary})
	end

	# Test 11
	test "Itinerary only for a single valid connection is forwarded to the next station (testing for multiple stations)" do

		connection = %Connection{vehicleID: "200", src_station: 1,
		mode_of_transport: "bus",
		dst_station: 2, dept_time: 25_000, arrival_time: 35_000}

		connection_1a = connection
		connection_1b = %Connection{connection | vehicleID: "202"}

		connection_2a = %Connection{connection | vehicleID: "300", dst_station: 3}
		connection_2b = %Connection{connection | vehicleID: "303", dst_station: 3}

		connection_3a = %Connection{connection | vehicleID: "400", dst_station: 4}
		connection_3b = %Connection{connection | vehicleID: "404", dst_station: 4}

		station_state = %StationStruct{loc_vars: %{"delay": 0.38,
			"congestion": "low", "disturbance": "no"},
			schedule: [connection_1a, connection_1b, connection_2a,
			connection_2b, connection_3a, connection_3b],
			station_number: 1, congestion_low: 4, choose_fn: 1}

		# Station state of Neighbour : %StationStruct{loc_vars: %{"delay": 0.38,
		# 	"congestion": "low", "disturbance": "no"},
		# 	schedule: [], congestion_low: 4, choose_fn: 1}

		itinerary = Itinerary.new(%Query{qid: "0300", src_station: 0,
		dst_station: 3, arrival_time: 0, end_time: 999_999},
			[%Connection{vehicleID: "99", src_station: 0, mode_of_transport: "train",
			dst_station: 1, dept_time: 10_000, arrival_time: 20_000}],
			%Preference{day: 0})

		proper_itinerary_1a = Itinerary.add_link(itinerary, connection_1a)
		proper_itinerary_1b = Itinerary.add_link(itinerary, connection_1b)
		proper_itinerary_2a = Itinerary.add_link(itinerary, connection_2a)
		proper_itinerary_2b = Itinerary.add_link(itinerary, connection_2b)
		proper_itinerary_3a = Itinerary.add_link(itinerary, connection_3a)
		proper_itinerary_3b = Itinerary.add_link(itinerary, connection_3b)

		test_proc = self()

		dependency = %Dependency{station: MockStation,
		registry: MockRegister,
		collector: MockCollector,
		itinerary: Itinerary}

		neighbour1 = :c.pid(0, 0, 200)
		neighbour2 = :c.pid(0, 0, 300)
		neighbour3 = :c.pid(0, 0, 400)

		{:ok, pid} = Station.start_link [station_state,
		dependency]

		# Define the expectation for the Mock of the Network Constructor
		MockRegister
		|> expect(:lookup_code, fn(2) -> neighbour1 end)
		|> expect(:lookup_code, fn(3) -> neighbour2 end)
		|> expect(:lookup_code, fn(4) -> neighbour3 end)
		|> expect(:check_active, fn(_) -> true end)

		MockStation
		|> expect(:send_query, 3,
			fn
				(^neighbour1, itinerary) ->
					send(test_proc, {:itinerary_received_in_2, itinerary})

				(^neighbour2, itinerary) ->
					send(test_proc, {:itinerary_received_in_3, itinerary})

				(^neighbour3, itinerary) ->
					 send(test_proc, {:itinerary_received_in_4, itinerary})
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

		assert_receive({:itinerary_received_in_2, ^proper_itinerary_1a})
		refute_receive({:itinerary_received_in_2, ^proper_itinerary_1b})

		assert_receive({:itinerary_received_in_3, ^proper_itinerary_2a})
		refute_receive({:itinerary_received_in_3, ^proper_itinerary_2b})

		assert_receive({:itinerary_received_in_4, ^proper_itinerary_3a})
		refute_receive({:itinerary_received_in_4, ^proper_itinerary_3b})
	end

	# Test 12
	test "The correct itinerary is forwarded to the next station with the
	updated day" do
		station_state = %StationStruct{loc_vars: %{"delay": 0.38,
			"congestion": "low", "disturbance": "no"},
			schedule: [%Connection{vehicleID: "100", src_station: 1,
			mode_of_transport: "bus",
			dst_station: 2, dept_time: 25_000, arrival_time: 35_000}],
			station_number: 1,
			congestion_low: 4, choose_fn: 1}

		# Station state of Neighbour : %StationStruct{loc_vars: %{"delay": 0.38,
		# 	"congestion": "low", "disturbance": "no"},
		# 	schedule: [], congestion_low: 4, choose_fn: 1}

		itinerary = Itinerary.new(%Query{qid: "0300", src_station: 0,
		dst_station: 3, arrival_time: 0, end_time: 999_999},
		[%Connection{vehicleID: "99", src_station: 0, mode_of_transport: "train",
			dst_station: 1, dept_time: 10_000, arrival_time: 86_400}],
			%Preference{day: 0})

		proper_itinerary = Itinerary.add_link(itinerary,
		%Connection{vehicleID: "100", src_station: 1, mode_of_transport: "bus",
		dst_station: 2, dept_time: 25_000, arrival_time: 35_000})
		proper_itinerary = Itinerary.increment_day(proper_itinerary, 1)

		test_proc = self()

		dependency = %Dependency{station: MockStation,
		registry: MockRegister,
		collector: MockCollector,
		itinerary: Itinerary}

		{:ok, pid} = Station.start_link [station_state,
		dependency]

		# Define the expectation for the Mock of the Network Constructor
		MockRegister
		|> expect(:lookup_code, fn(_) -> test_proc end)
		|> expect(:check_active, fn(_) -> true end)

		MockStation
		|> expect(:send_query, fn(^test_proc, processed_itinerary) ->
			send(test_proc, {:itinerary_received, processed_itinerary})
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

	# Test 13
	test "Terminated queries are handed over to query collector with correct itinerary" do
		station_state = %StationStruct{loc_vars: %{"delay": 0.38,
			"congestion": "low", "disturbance": "no"},
			schedule: [%Connection{vehicleID: "100", src_station: 1,
			 mode_of_transport: "bus",
			dst_station: 2, dept_time: 25_000, arrival_time: 35_000}],
			congestion_low: 4, choose_fn: 1}

		itinerary = Itinerary.new(%Query{qid: "0100", src_station: 0,
		dst_station: 1, arrival_time: 0, end_time: 999_999},
		[%Connection{vehicleID: "99", src_station: 0, mode_of_transport: "train",
			dst_station: 1, dept_time: 10_000, arrival_time: 20_000}],
			%Preference{day: 0})

		test_proc = self()

		dependency = %Dependency{station: MockStation,
		registry: MockRegister,
		collector: MockCollector,
		itinerary: Itinerary}

		# Define the expectation for the Mock of the Network Constructor
		MockRegister
		|> expect(:check_active, fn(_) -> true end)

		# Define the expectation for the Mock of the Query Collector
		MockCollector
		|> expect(:collect, fn(itinerary) ->
			send(test_proc, {:itinerary_received, itinerary}) end)

		MockStation
 		|> expect(:send_query, fn(_, _) ->
 			send(test_proc, :collected_query_forwarded)
 			end)

		{:ok, pid} = Station.start_link [station_state,
 		dependency]

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

	# Test 14
	test "Station Schedule is not changed after processing a query" do
		connection = %Connection{vehicleID: "200", src_station: 1,
		mode_of_transport: "bus",
		dst_station: 2, dept_time: 25_000, arrival_time: 35_000}

		connection_1a = connection
		connection_1b = %Connection{connection | vehicleID: "202"}

		connection_2a = %Connection{connection | vehicleID: "300", dst_station: 3}
		connection_2b = %Connection{connection | vehicleID: "303", dst_station: 3}

		connection_3a = %Connection{connection | vehicleID: "400", dst_station: 4}
		connection_3b = %Connection{connection | vehicleID: "404", dst_station: 4}

		timetable = [connection_1a, connection_1b, connection_2a, connection_2b,
		connection_3a, connection_3b]
		station_state = %StationStruct{loc_vars: %{"delay": 0.38,
			"congestion": "low", "disturbance": "no"},
			schedule: timetable,
			station_number: 1, congestion_low: 4, choose_fn: 1}

		# Station state of Neighbour : %StationStruct{loc_vars: %{"delay": 0.38,
		# 	"congestion": "low", "disturbance": "no"},
		# 	schedule: [], congestion_low: 4, choose_fn: 1}

		itinerary = Itinerary.new(%Query{qid: "0300", src_station: 0,
		dst_station: 3, arrival_time: 0, end_time: 999_999},
			[%Connection{vehicleID: "99", src_station: 0, mode_of_transport: "train",
			dst_station: 1, dept_time: 10_000, arrival_time: 20_000}],
			%Preference{day: 0})

		test_proc = self()

		dependency = %Dependency{station: MockStation,
		registry: MockRegister,
		collector: MockCollector,
		itinerary: Itinerary}

		{:ok, pid} = Station.start_link [station_state,
		dependency]

		# Define the expectation for the Mock of the Network Constructor
		MockRegister
		|> expect(:lookup_code, 3, fn(_) -> test_proc end)
		|> expect(:check_active, fn(_) -> true end)

		MockStation
		|> expect(:send_query, 3, fn (_, _) -> nil end)

		# Give The Station Process access to mocks defined in the test process
		allow(MockRegister, test_proc, pid)
		allow(MockCollector, test_proc, pid)
		allow(MockStation, test_proc, pid)

		# Send query to station
		Station.send_query(pid, itinerary)

		# Assert that the Station
		assert Station.get_timetable(pid) == timetable

		# Stop station normally
		Station.stop(pid)
	end

	# Test 15
	# Test to check if the station consumes a given number of
	# streams within a stipulated amount of time.
	test "Consumes rapid stream of mixed input queries" do
		query = Itinerary.new(%Query{qid: "0100", src_station: 0, dst_station: 1,
			arrival_time: 0, end_time: 999_999}, %Preference{day: 0})

		station_state = %StationStruct{loc_vars: %{"delay": 0.38,
			"congestion": "low", "disturbance": "no"},
			schedule: [%Connection{vehicleID: "100", src_station: 1,
			mode_of_transport: "bus",
			dst_station: 2, dept_time: 25_000, arrival_time: 35_000}],
			congestion_low: 4, choose_fn: 1}

		test_proc = self()

		dependency = %Dependency{station: MockStation,
		registry: MockRegister,
		collector: MockCollector,
		itinerary: Itinerary}

		# Start station
		{:ok, pid} = Station.start_link [station_state,
		dependency]

		# Define the expectation for the Mock of the Network Constructor
		MockRegister
		|> stub(:lookup_code, fn(_) -> test_proc end)
		|> stub(:check_active, fn(_) ->
			true
			end)

		MockStation
 		|> stub(:send_query, fn(_, _) -> nil end)

		# Give The Station Process access to mocks defined in the test process
		allow(MockRegister, test_proc, pid)
		allow(MockCollector, test_proc, pid)
		allow(MockStation, test_proc, pid)

		# Send 1000 queries
		send_message(query, 1000, pid)

		# Sleep for 1000 milliseconds
		:timer.sleep(1000)

		# Check if length of message queue is 0
		{:message_queue_len, queue_len} = :erlang.process_info(pid,
			:message_queue_len)
		assert queue_len == 0

		# Send 10_000 queries
		send_message(query, 10_000, pid)

		:timer.sleep(1000)

		{:message_queue_len, queue_len} = :erlang.process_info(pid,
			:message_queue_len)
		assert queue_len == 0

		# Send 10_000 queries
		send_message(query, 100_000, pid)

		:timer.sleep(1000)

		{:message_queue_len, queue_len} = :erlang.process_info(pid,
			:message_queue_len)
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

	def wait_for_process_termination(pid) do
		if Process.alive?(pid) do
			:timer.sleep(10)
			wait_for_process_termination(pid)
		end
	end

end
