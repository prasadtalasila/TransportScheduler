defmodule StationTest do
	@moduledoc"""
	Module to test Station.
	Create new station process with associated FSM and updates local variable
	values. It also tests the interaction of one station with the others.
	It also tests the validity of a query and the interaction of the Station
	with the Query Collector.
	"""

	#The test values for the station states and itineraries are as of yet unassigned

	#set async:true in test servers for concurrent tests
	use ExUnit.Case, async: false
	import Mox

	setup_all do
		Mox.defmock(MockCollector, for: TS.Collector)
		Mox.defmock(MockRegister, for: TS.Registry)
		:ok
	end

	# Test 1

	# Test to see if data can be retrieved from the station correctly
	test "retrieving the given schedule" do

		#Station Schedule
		schedule = [%{vehicleID: "100", src_station: 1, mode_of_transport: "bus",
		dst_station: 2, dept_time: 25_000, arrival_time: 35_000}]

		station_state = %StationStruct{loc_vars: %{"delay": 0.12,
			"congestion": "low", "disturbance": "no"},
			schedule: schedule, station_number: 1710,
			station_name: "Mumbai", congestion_low: 3, choose_fn: 2}

		# Start the server

		{:ok, pid} = start_supervised({Station, [station_state,
		MockRegister, MockCollector]})

		# Retrieve Time Table
		assert Station.get_timetable(pid) == schedule

	end

	# Test 2

	# Test to see if the station schedule can be updated
	test "updating the station schedule" do

		#Station Schedule
		schedule = [%{vehicleID: "100", src_station: 1, mode_of_transport: "bus",
		dst_station: 2, dept_time: 25_000, arrival_time: 35_000}]

		new_schedule = [%{vehicleID: "88", src_station: 1, mode_of_transport: "train",
		dst_station: 2, dept_time: 12_000, arrival_time: 24_000},
		%{vehicleID: "100", src_station: 1, mode_of_transport: "bus",
		dst_station: 2, dept_time: 25_000, arrival_time: 35_000}]

		station_state = %StationStruct{loc_vars: %{"delay": 0.12,
			"congestion": "low", "disturbance": "no"},
			schedule: schedule, station_number: 1710,
			station_name: "Mumbai", congestion_low: 3, choose_fn: 2}



		# Start the server

		{:ok, pid} = start_supervised({Station, [station_state,
		MockRegister, MockCollector]})

		new_station_state = %{station_state | schedule: new_schedule}

		Station.update(pid, new_station_state)

		# Retrieve the Time Table and check if it has been updated
		assert Station.get_timetable(pid) == new_schedule

	end

	# Test 3
	test "Receive a itinerary search query" do

		# Set function parameters to arbitrary values.
		# effect only after the station has received the query.
		query = [%{qid: "0300", src_station: 0, dst_station: 3, day: 0, arrival_time: 0}]
		# Any errors due to invalid values do not matter as they will come into

		station_state = %StationStruct{loc_vars: %{"delay": 0.38,
			"congestion": "low", "disturbance": "no"},
			schedule: [%{vehicleID: "100", src_station: 1, mode_of_transport: "bus",
			dst_station: 2, dept_time: 25_000, arrival_time: 35_000}], station_number: 1,
			congestion_low: 4, choose_fn: 1}

		test_proc = self()
		mock_send_to_stn = {fn(_) -> false end}
		#Create mock station
		{:ok, neighbour} = MockStation.start_link(mock_send_to_stn)

		#Create NetworkConstructor Mock
		MockRegister
		|> expect(:check_active,
			fn(_) -> send(test_proc, :query_received)
			false
			end)
		|> expect(:lookup_code, fn(_) -> neighbour end)

		#start station
		{:ok, pid} = start_supervised({Station, [station_state, MockRegister, MockCollector]})

		#Give The Station Process access to mocks defined in the test process
		allow(MockRegister, test_proc, pid)
		allow(MockCollector, test_proc, pid)

		#Send query to station
		Station.send_query(pid, query)

		assert_receive :query_received
	end

	# Test 4
	test "Send completed search query to neighbours" do
		station_state = %StationStruct{loc_vars: %{"delay": 0.38,
			"congestion": "low", "disturbance": "no"},
			schedule: [%{vehicleID: "100", src_station: 1, mode_of_transport: "bus",
			dst_station: 2, dept_time: 25_000, arrival_time: 35_000}], station_number: 1,
			congestion_low: 4, choose_fn: 1}

		# Station state of Neighbour : %StationStruct{loc_vars: %{"delay": 0.38,
		# 	"congestion": "low", "disturbance": "no"},
		# 	schedule: [], congestion_low: 4, choose_fn: 1}

		itinerary = [%{qid: "0300", src_station: 0, dst_station: 3, day: 0, arrival_time: 0, end_time: 999_999},
		%{vehicleID: "99", src_station: 0, mode_of_transport: "train",
		dst_station: 1, dept_time: 10_000, arrival_time: 20_000}]

		test_proc = self()
		mock_send_to_stn = {fn(_) -> send(test_proc, :query_received)
			end}

		{:ok, pid} = start_supervised({Station, [station_state,
			MockRegister, MockCollector]})
		{:ok, neighbour} = start_supervised({MockStation, mock_send_to_stn})

		# Define the expectation for the Mock of the Network Constructor
		MockRegister
		|> expect(:lookup_code, fn(_) -> neighbour end)
		|> expect(:check_active, fn(_) -> true end)

		#Give The Station Process access to mocks defined in the test process
		allow(MockRegister, test_proc, pid)
		allow(MockCollector, test_proc, pid)

		Station.send_query(pid, itinerary)

		assert_receive :query_received
	end

	# Test 5
	test "Does not forward stale queries" do
		station_state = %StationStruct{loc_vars: %{"delay": 0.38,
			"congestion": "low", "disturbance": "no"},
			schedule: [%{vehicleID: "100", src_station: 1, mode_of_transport: "bus",
			dst_station: 2, dept_time: 25_000, arrival_time: 35_000}], station_number: 1,
			congestion_low: 4, choose_fn: 1}

		# Station state of Neighbour : %StationStruct{loc_vars: %{"delay": 0.38,
		# 	"congestion": "low", "disturbance": "no"},
		# 	schedule: [], congestion_low: 4, choose_fn: 1}

		itinerary = [%{qid: "0300", src_station: 0, dst_station: 3, day: 0, arrival_time: 0, end_time: 999_999},
			%{vehicleID: "99", src_station: 0, mode_of_transport: "train",
			dst_station: 1, dept_time: 10_000, arrival_time: 20_000}]

		test_proc = self()
		mock_send_to_stn = {fn(_) -> send(test_proc, :stale_query_forwarded)
		end}

		{:ok, pid} = start_supervised({Station, [station_state,
			MockRegister, MockCollector]})
		{:ok, neighbour} = start_supervised({MockStation, mock_send_to_stn})

		# Define the expectation for the Mock of the Network Constructor
		MockRegister
		|> expect(:lookup_code, fn(_) -> neighbour end)
		|> expect(:check_active, fn(_) -> false end)

		#Give The Station Process access to mocks defined in the test process
		allow(MockRegister, test_proc, pid)
		allow(MockCollector, test_proc, pid)

		Station.send_query(pid, itinerary)

		# Query should not be forwarded to neighbour
		refute_receive(:stale_query_forwarded)
	end

	# Test 6
	test "Does not forward queries with self loops" do
		station_state = %StationStruct{loc_vars: %{"delay": 0.38,
			"congestion": "low", "disturbance": "no"},
			schedule: [%{vehicleID: "100", src_station: 1, mode_of_transport: "bus",
			dst_station: 2, dept_time: 25_000, arrival_time: 35_000}], station_number: 1,
			congestion_low: 4, choose_fn: 1}

		# Station state of Neighbour : %StationStruct{loc_vars: %{"delay": 0.38,
		# 	"congestion": "low", "disturbance": "no"},
		# 	schedule: [], congestion_low: 4, choose_fn: 1}

		itinerary = [%{qid: "0300", src_station: 1, dst_station: 3, day: 0, arrival_time: 0, end_time: 999_999},
			%{vehicleID: "99", src_station: 1, mode_of_transport: "train",
			dst_station: 2, dept_time: 10_000, arrival_time: 20_000}, %{vehicleID: "100", src_station: 2, mode_of_transport: "train",
			dst_station: 1, dept_time: 25_000, arrival_time: 30_000}]

		test_proc = self()
		mock_send_to_stn = {fn(_) -> send(test_proc, :query_with_self_loop_forwarded)
		end}

		{:ok, pid} = start_supervised({Station, [station_state,
			MockRegister, MockCollector]})
		{:ok, neighbour} = start_supervised({MockStation, mock_send_to_stn})

		# Define the expectation for the Mock of the Network Constructor
		MockRegister
		|> expect(:lookup_code, fn(_) -> neighbour end)
		|> expect(:check_active, fn(_) -> true end)

		#Give The Station Process access to mocks defined in the test process
		allow(MockRegister, test_proc, pid)
		allow(MockCollector, test_proc, pid)

		Station.send_query(pid, itinerary)

		# Query should not be forwarded to neighbour
		refute_receive(:stale_query_forwarded)
	end

	# Test 7
	test "Incorrectly received queries are discarded" do
		station_state = %StationStruct{loc_vars: %{"delay": 0.38,
			"congestion": "low", "disturbance": "no"},
			schedule: [%{vehicleID: "100", src_station: 1, mode_of_transport: "bus",
			dst_station: 2, dept_time: 25_000, arrival_time: 35_000}], station_number: 1,
			congestion_low: 4, choose_fn: 1}

		# Station state of Neighbour : %StationStruct{loc_vars: %{"delay": 0.38,
		# 	"congestion": "low", "disturbance": "no"},
		# 	schedule: [], congestion_low: 4, choose_fn: 1}

		itinerary = [%{qid: "0300", src_station: 0, dst_station: 3, day: 0, arrival_time: 0, end_time: 999_999},
			%{vehicleID: "99", src_station: 0, mode_of_transport: "train",
			dst_station: 5, dept_time: 10_000, arrival_time: 20_000}]

		test_proc = self()
		mock_send_to_stn = {fn(_, _) ->
			send(test_proc, :incorrect_query_forwarded)
		end}

		{:ok, pid} = start_supervised({Station, [station_state,
			MockRegister, MockCollector]})
		{:ok, neighbour} = start_supervised({MockStation, mock_send_to_stn})

		# Define the expectation for the Mock of the Network Constructor
		MockRegister
		|> expect(:lookup_code, fn(_) -> neighbour end)
		|> expect(:check_active, fn(_) -> true end)

		#Give The Station Process access to mocks defined in the test process
		allow(MockRegister, test_proc, pid)
		allow(MockCollector, test_proc, pid)

		Station.send_query(pid, itinerary)

		# Query should not be forwarded to neighbour
		refute_receive(:incorrect_query_forwarded)
	end

	#Test 8
	test "No query is forwarded from a Station with no viable paths
	(no viable neighbouring station)." do
		station_state = %StationStruct{loc_vars: %{"delay": 0.38,
			"congestion": "low", "disturbance": "no"},
			schedule: [%{vehicleID: "100", src_station: 1, mode_of_transport: "bus",
			dst_station: 2, dept_time: 15_000, arrival_time: 35_000}], station_number: 1,
			congestion_low: 4, choose_fn: 1}

		# Station state of Neighbour : %StationStruct{loc_vars: %{"delay": 0.38,
		# 	"congestion": "low", "disturbance": "no"},
		# 	schedule: [], congestion_low: 4, choose_fn: 1}

		itinerary = [%{qid: "0300", src_station: 0, dst_station: 3, day: 0, arrival_time: 0, end_time: 999_999},
			%{vehicleID: "99", src_station: 0, mode_of_transport: "train",
			dst_station: 1, dept_time: 10_000, arrival_time: 20_000}]

		test_proc = self()
		mock_send_to_stn = {fn(_, _) ->
			send(test_proc, :query_forwarded)
		end}

		{:ok, pid} = start_supervised({Station, [station_state,
			MockRegister, MockCollector]})
		{:ok, neighbour} = start_supervised({MockStation, mock_send_to_stn})

		# Define the expectation for the Mock of the Network Constructor
		MockRegister
		|> expect(:lookup_code, fn(_) -> neighbour end)
		|> expect(:check_active, fn(_) -> true end)

		#Give The Station Process access to mocks defined in the test process
		allow(MockRegister, test_proc, pid)
		allow(MockCollector, test_proc, pid)


		Station.send_query(pid, itinerary)

		# Query should not be forwarded to neighbour
		refute_receive(:query_forwarded)
	end

	#Test 9
	test "The correct itinerary is forwarded to the next station" do
		station_state = %StationStruct{loc_vars: %{"delay": 0.38,
			"congestion": "low", "disturbance": "no"},
			schedule: [%{vehicleID: "100", src_station: 1, mode_of_transport: "bus",
			dst_station: 2, dept_time: 25_000, arrival_time: 35_000}], station_number: 1,
			congestion_low: 4, choose_fn: 1}

		# Station state of Neighbour : %StationStruct{loc_vars: %{"delay": 0.38,
		# 	"congestion": "low", "disturbance": "no"},
		# 	schedule: [], congestion_low: 4, choose_fn: 1}

		itinerary = [%{qid: "0300", src_station: 0, dst_station: 3, day: 0, arrival_time: 0, end_time: 999_999},
			%{vehicleID: "99", src_station: 0, mode_of_transport: "train",
			dst_station: 1, dept_time: 10_000, arrival_time: 20_000}]

		proper_itinerary = [%{qid: "0300", src_station: 0, dst_station: 3, day: 0, arrival_time: 0, end_time: 999_999},
				%{vehicleID: "99", src_station: 0, mode_of_transport: "train",
				dst_station: 1, dept_time: 10_000, arrival_time: 20_000},
				%{vehicleID: "100", src_station: 1, mode_of_transport: "bus",
				dst_station: 2, dept_time: 25_000, arrival_time: 35_000}]

		test_proc = self()

		mock_receive_at_stn = {fn(y) -> send(test_proc, {:itinerary_received, y}) end}

		{:ok, pid} = start_supervised({Station, [station_state,
			MockRegister, MockCollector]})
		{:ok, neighbour} = start_supervised({MockStation, mock_receive_at_stn})

		# Define the expectation for the Mock of the Network Constructor
		MockRegister
		|> expect(:lookup_code, fn(_) -> neighbour end)
		|> expect(:check_active, fn(_) -> true end)

		#Give The Station Process access to mocks defined in the test process
		allow(MockRegister, test_proc, pid)
		allow(MockCollector, test_proc, pid)

		Station.send_query(pid, itinerary)

		# Query should not be forwarded to neighbour
		assert_receive({:itinerary_received, ^proper_itinerary})
	end

	# Test 10
	test "The correct itinerary is forwarded to the next station with the
	updated day" do
		station_state = %StationStruct{loc_vars: %{"delay": 0.38,
			"congestion": "low", "disturbance": "no"},
			schedule: [%{vehicleID: "100", src_station: 1, mode_of_transport: "bus",
			dst_station: 2, dept_time: 25_000, arrival_time: 35_000}], station_number: 1,
			congestion_low: 4, choose_fn: 1}

		# Station state of Neighbour : %StationStruct{loc_vars: %{"delay": 0.38,
		# 	"congestion": "low", "disturbance": "no"},
		# 	schedule: [], congestion_low: 4, choose_fn: 1}

		itinerary = [%{qid: "0300", src_station: 0, dst_station: 3, day: 0, arrival_time: 0, end_time: 999_999},
			%{vehicleID: "99", src_station: 0, mode_of_transport: "train",
			dst_station: 1, dept_time: 10_000, arrival_time: 86_400}]

		proper_itinerary = [%{qid: "0300", src_station: 0, dst_station: 3, day: 1, arrival_time: 0, end_time: 999_999},
				%{vehicleID: "99", src_station: 0, mode_of_transport: "train",
				dst_station: 1, dept_time: 10_000, arrival_time: 86_400},
				%{vehicleID: "100", src_station: 1, mode_of_transport: "bus",
				dst_station: 2, dept_time: 25_000, arrival_time: 35_000}]

		test_proc = self()

		mock_receive_at_stn = {fn(y) -> send(test_proc, {:itinerary_received, y}) end}

		{:ok, pid} = start_supervised({Station, [station_state,
			MockRegister, MockCollector]})
		{:ok, neighbour} = start_supervised({MockStation, mock_receive_at_stn})

		# Define the expectation for the Mock of the Network Constructor
		MockRegister
		|> expect(:lookup_code, fn(_) -> neighbour end)
		|> expect(:check_active, fn(_) -> true end)

		#Give The Station Process access to mocks defined in the test process
		allow(MockRegister, test_proc, pid)
		allow(MockCollector, test_proc, pid)

		Station.send_query(pid, itinerary)

		# Query should not be forwarded to neighbour
		assert_receive({:itinerary_received, ^proper_itinerary})
	end

	# Test 11
	test "Terminated queries are handed over to query collector with correct itinerary" do
		station_state = %StationStruct{loc_vars: %{"delay": 0.38,
			"congestion": "low", "disturbance": "no"},
			schedule: [%{vehicleID: "100", src_station: 1, mode_of_transport: "bus",
			dst_station: 2, dept_time: 25_000, arrival_time: 35_000}],
			congestion_low: 4, choose_fn: 1}

		itinerary = [%{qid: "0100", src_station: 0, dst_station: 1, day: 0, arrival_time: 0, end_time: 999_999},
			%{vehicleID: "99", src_station: 0, mode_of_transport: "train",
			dst_station: 1, dept_time: 10_000, arrival_time: 20_000}]

		proper_itinerary = [%{qid: "0100", src_station: 0, dst_station: 1, day: 0, arrival_time: 0, end_time: 999_999},
			%{vehicleID: "99", src_station: 0, mode_of_transport: "train",
			dst_station: 1, dept_time: 10_000, arrival_time: 20_000}]

		test_proc = self()

		# Define the expectation for the Mock of the Network Constructor
		MockRegister
		|> expect(:check_active, fn(_) -> true end)

		# Define the expectation for the Mock of the Query Collector
		MockCollector
		|> expect(:collect, fn(itinerary) -> send(test_proc, {:query_received, itinerary})
		 end)

		{:ok, pid} = start_supervised({Station, [station_state,
			MockRegister, MockCollector]})

		#Give The Station Process access to mocks defined in the test process
		allow(MockRegister, test_proc, pid)
		allow(MockCollector, test_proc, pid)

		Station.send_query(pid, itinerary)
		assert_receive({:query_received, ^proper_itinerary})
	end

	#Test 12
	#Test to check if the station consumes a given number of
	#streams within a stipulated amount of time.
	test "Consumes rapid stream of mixed input queries" do
		query = [%{qid: "0100", src_station: 0, dst_station: 1, day: 0, arrival_time: 0, end_time: 999_999}]

		station_state = %StationStruct{loc_vars: %{"delay": 0.38,
			"congestion": "low", "disturbance": "no"},
			schedule: [%{vehicleID: "100", src_station: 1, mode_of_transport: "bus",
			dst_station: 2, dept_time: 25_000, arrival_time: 35_000}],
			congestion_low: 4, choose_fn: 1}

		test_proc = self()
		mock_receive_at_stn = {fn(_) -> false end}

		# Start station
		{:ok, pid} = start_supervised({Station, [station_state,
			MockRegister, MockCollector]})
		{:ok, mock_pid} = start_supervised({MockStation, mock_receive_at_stn})

		# Define the expectation for the Mock of the Network Constructor
		MockRegister
		|> stub(:lookup_code, fn(_) -> mock_pid end)
		|> stub(:check_active, fn(_) ->
			true
			end)

		#Give The Station Process access to mocks defined in the test process
		allow(MockRegister, test_proc, pid)
		allow(MockCollector, test_proc, pid)

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

		#Send 10_000 queries
		send_message(query, 100_000, pid)

		:timer.sleep(1000)

		{:message_queue_len, queue_len} = :erlang.process_info(pid,
			:message_queue_len)
		assert queue_len != 0

		stop_supervised(Station)
		stop_supervised(MockStation)

	end

	def send_message(_msg, 0, _pid) do
	end

	# A function to send 'n' number of messages to given pid
	def send_message(msg, n, pid) do
		Station.send_query(pid, msg)
		send_message(msg, n-1, pid)
	end

end
