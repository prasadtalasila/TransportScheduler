defmodule StationTest do
	@moduledoc"""
	Module to test Station.
	Create new station process with associated FSM and updates local variable
	values. It also tests the interaction of one station with the others.
	It also tests the validity of a query and the interaction of the Station
	with the Query Collector.
	"""

	#The test values for the station states and itineraries are as of yet unassigned

	use ExUnit.Case, async: false
	import Mox

	setup_all do
		Mox.defmock(MockCollector, for: TS.Collector)
		Mox.defmock(MockRegister, for: TS.Registry)
		:ok
	end

	# Test 1

	# Test to see if the given state is stored by updating
	# some variables
	test "stores the given state" do
		# Start the server
		stationState = %StationStruct{loc_vars: %{"delay": 0.38,
			"congestion": "low", "disturbance": "no"},
			schedule: [], congestion_low: 4, choose_fn: 1}

		# {:ok, station} = start_supervised(Station,[stationState,
		# 	MockRegister, MockCollector])
		{:ok, station} = Station.start_link([stationState,
			MockRegister, MockCollector])

		# Verify values from StationStruct
		assert Station.get_vars(station).loc_vars.delay == 0.38
		#assert Station.get_vars(station).loc_vars.congestion_delay == 0.38 * 4
		assert Station.get_state(station) == :delay
	end

	# Test 2

	# Test to see if data can be retrieved from the station correctly
	test "retrieving the given state" do

		stationState = %StationStruct{loc_vars: %{"delay": 0.12,
			"congestion": "low", "disturbance": "no"},
			schedule: [], station_number: 1710,
			station_name: "Mumbai", congestion_low: 3, choose_fn: 2}

		# Start the server
		#{:ok, station} = start_supervised(Station,[stationState,
		#	MockRegister, MockCollector])

		{:ok, station} = Station.start_link([stationState,
			MockRegister, MockCollector])

		# Retrieve values from loc_vars
		assert Station.get_vars(station).loc_vars.delay == 0.12
		assert Station.get_vars(station).loc_vars.congestion == "low"
		assert Station.get_vars(station).loc_vars.disturbance == "no"

		# Retrieve other values from StationStruct
		assert Station.get_vars(station).station_number == 1710
		assert Station.get_vars(station).station_name == "Mumbai"
		#assert Station.get_vars(station).congestion_delay == 0.12 * 3 + 0.2
	end

	# Test 3

	# Test to see if the state gets updated once new variable
	# values are given
	test "updating the given state" do

		stationState = %StationStruct{loc_vars: %{"delay": 0.38,
			"congestion": "low", "disturbance": "no"},
			schedule: [], congestion_low: 4, choose_fn: 1}

		# Start the server
		{:ok, station} = start_supervised(Station,[stationState,
			MockRegister, MockCollector])

		# Check to see if change has taken place
		assert Station.get_vars(station).loc_vars.congestion_delay == 0.38 * 4

		# Update state again
		Station.update(station, %StationStruct{loc_vars: %{"delay": 0.0,
			"congestion": "none", "disturbance": "no"},
			schedule: [], station_name: "Panjim", choose_fn: 1})

		# Check to see if update has taken place
		assert Station.get_vars(station).loc_vars.disturbance == "no"
		#assert Station.get_vars(station).loc_vars.congestion_delay == 0.0
		assert Station.get_vars(station).station_name == "Panjim"
	end

# 	# Test 4

	test "Receive a itinerary search query" do

		# Set function parameters to arbitrary values.
		# Any errors due to invalid values do not matter as they will come into
		# effect only after the station has received the query.
		query = [%{qid: "0300", src_station: 0, dst_station: 3, day: 0, arrival_time: 0}]

		stationState = %StationStruct{loc_vars: %{"delay": 0.38,
			"congestion": "low", "disturbance": "no"},
			schedule: [%{vehicleID: "100", src_station: 1, mode_of_transport: "bus",
			dst_station: 2, dept_time: 25000, arrival_time: 35000}],
			congestion_low: 4, choose_fn: 1}

		test_proc=self()
		mock_send_to_stn = { fn(_,_) -> false end}

		#start station
		{:ok,pid}=start_supervised(Station,[stationState,
			MockRegister, MockCollector])
		{:ok,neighbour}=start_supervised(MockStation,mock_send_to_stn)

		MockRegister
		|> expect(:check_active,
			fn(_) -> send(test_proc, :query_received)
			false
			end)
		|> expect(:lookup_code, fn(_) -> neighbour end)

		#Send query to station
		Station.receive_at_src(pid, query)

		#assert that the station has received a message :query_received
		assert_receive(:query_received)


	end

	# Test 5

	test "Send completed search query to neighbours" do
		stationState = %StationStruct{loc_vars: %{"delay": 0.38,
			"congestion": "low", "disturbance": "no"},
			schedule: [%{vehicleID: "100", src_station: 1, mode_of_transport: "bus",
			dst_station: 2, dept_time: 25000, arrival_time: 35000}],
			congestion_low: 4, choose_fn: 1}

		# Station state of Neighbour : %StationStruct{loc_vars: %{"delay": 0.38,
		# 	"congestion": "low", "disturbance": "no"},
		# 	schedule: [], congestion_low: 4, choose_fn: 1}

		itinerary = [%{qid: "0300", src_station: 0, dst_station: 3, day: 0, arrival_time: 0},
		%{vehicleID: "99", src_station: 0, mode_of_transport: "train",
		dst_station: 1, dept_time: 10000, arrival_time: 20000}]

		test_proc=self()
		mock_send_to_stn = { fn(_,_) -> send(test_proc, :query_received)
			end }


		{:ok,pid}=start_supervised(Station,[stationState,
			MockRegister, MockCollector])
		{:ok,neighbour}=start_supervised(MockStation,mock_send_to_stn)


		MockRegister
		|> expect(:lookup_code, fn(_) -> neighbour end)
		|> expect(:check_active, fn(_) -> true end)


		Station.send_to_stn(self(), pid, itinerary)

		assert_receive :query_received


	end

	# Test 6

	test "Does not forward itineraries with potential self-loops" do
		stationState = %StationStruct{loc_vars: %{"delay": 0.38,
			"congestion": "low", "disturbance": "no"},
			schedule: [%{vehicleID: "100", src_station: 1, mode_of_transport: "bus",
			dst_station: 0, dept_time: 25000, arrival_time: 35000}],
			congestion_low: 4, choose_fn: 1}

		# Station state of Neighbour : %StationStruct{loc_vars: %{"delay": 0.38,
		# 	"congestion": "low", "disturbance": "no"},
		# 	schedule: [], congestion_low: 4, choose_fn: 1}

		itinerary = [%{qid: "0300", src_station: 0, dst_station: 3, day: 0, arrival_time: 0},
			%{vehicleID: "99", src_station: 0, mode_of_transport: "train",
			dst_station: 1, dept_time: 10000, arrival_time: 20000}]

		test_proc=self()
		mock_send_to_stn = { fn(_,_) -> send(test_proc, :query_with_selfloop_forwarded)
		end}

		{:ok,pid}=start_supervised(Station,[stationState,
			MockRegister, MockCollector])
		{:ok,neighbour}=start_supervised(MockStation,mock_send_to_stn)

		MockRegister
		|> expect(:lookup_code, fn(_) -> neighbour end)
		|> expect(:check_active, fn(_) -> true end)


		Station.send_to_stn(self() , pid, itinerary)

		# Query should not be forwarded to neighbour
		refute_receive(:query_with_selfloop_forwarded)

	end

	# Test 7

	test "Does not forward stale queries" do
		stationState = %StationStruct{loc_vars: %{"delay": 0.38,
			"congestion": "low", "disturbance": "no"},
			schedule: [%{vehicleID: "100", src_station: 1, mode_of_transport: "bus",
			dst_station: 2, dept_time: 25000, arrival_time: 35000}],
			congestion_low: 4, choose_fn: 1}

		# Station state of Neighbour : %StationStruct{loc_vars: %{"delay": 0.38,
		# 	"congestion": "low", "disturbance": "no"},
		# 	schedule: [], congestion_low: 4, choose_fn: 1}

		itinerary = [%{qid: "0300", src_station: 0, dst_station: 3, day: 0, arrival_time: 0},
			%{vehicleID: "99", src_station: 0, mode_of_transport: "train",
			dst_station: 1, dept_time: 10000, arrival_time: 20000}]

		test_proc=self()
		mock_send_to_stn ={ fn(_,_) -> send(test_proc, :stale_query_forwarded)
		end }

		{:ok,pid}=start_supervised(Station,[stationState,
			MockRegister, MockCollector])
		{:ok,neighbour}=start_supervised(MockStation,mock_send_to_stn)

		MockRegister
		|> expect(:lookup_code, fn(_) -> neighbour end)
		|> expect(:check_active, fn(_) -> false end)


		Station.send_to_stn(self() , pid, itinerary)

		# Query should not be forwarded to neighbour
		refute_receive(:stale_query_forwarded)


	end

	# Test 8

	test "Incorrectly received queries are discarded" do
		stationState = %StationStruct{loc_vars: %{"delay": 0.38,
			"congestion": "low", "disturbance": "no"},
			schedule: [%{vehicleID: "100", src_station: 1, mode_of_transport: "bus",
			dst_station: 2, dept_time: 25000, arrival_time: 35000}],
			congestion_low: 4, choose_fn: 1}

		# Station state of Neighbour : %StationStruct{loc_vars: %{"delay": 0.38,
		# 	"congestion": "low", "disturbance": "no"},
		# 	schedule: [], congestion_low: 4, choose_fn: 1}

		itinerary = [%{qid: "0300", src_station: 0, dst_station: 3, day: 0, arrival_time: 0},
			%{vehicleID: "99", src_station: 0, mode_of_transport: "train",
			dst_station: 5, dept_time: 10000, arrival_time: 20000}]

		test_proc=self()
		mock_send_to_stn = { fn(_,_) ->
			send(test_proc, :incorrect_query_forwarded)
		end }

		{:ok,pid}=start_supervised(Station,[stationState,
			MockRegister, MockCollector])
		{:ok,neighbour}=start_supervised(MockStation,mock_send_to_stn)

		MockRegister
		|> expect(:lookup_code, fn(_) -> neighbour end)
		|> expect(:check_active, fn(_) -> true end)


		Station.send_to_stn(pid, itinerary)

		# Query should not be forwarded to neighbour
		refute_receive(:incorrect_query_forwarded)
	end

	# Test 9

	test "The correct itinerary is forwarded to the next station" do
		stationState = %StationStruct{loc_vars: %{"delay": 0.38,
			"congestion": "low", "disturbance": "no"},
			schedule: [%{vehicleID: "100", src_station: 1, mode_of_transport: "bus",
			dst_station: 2, dept_time: 25000, arrival_time: 35000}],
			congestion_low: 4, choose_fn: 1}

		# Station state of Neighbour : %StationStruct{loc_vars: %{"delay": 0.38,
		# 	"congestion": "low", "disturbance": "no"},
		# 	schedule: [], congestion_low: 4, choose_fn: 1}

		itinerary = [%{qid: "0300", src_station: 0, dst_station: 3, day: 0, arrival_time: 0},
			%{vehicleID: "99", src_station: 0, mode_of_transport: "train",
			dst_station: 1, dept_time: 10000, arrival_time: 20000}]

		proper_itinerary = [%{qid: "0301", src_station: 0, dst_station: 3, day: 0, arrival_time: 0},
				%{vehicleID: "99", src_station: 0, mode_of_transport: "train",
				dst_station: 1, dept_time: 10000, arrival_time: 20000},
				%{vehicleID: "100", src_station: 1, mode_of_transport: "bus",
				dst_station: 2, dept_time: 25000, arrival_time: 35000}]

		test_proc=self()

		mock_receive_at_stn= { fn(_, y) -> send(test_proc,{:itinerary_received,y}) end }

		{:ok,pid}=start_supervised(Station,[stationState,
			MockRegister, MockCollector])
		{:ok,neighbour}=start_supervised(MockStation,mock_receive_at_stn)

		MockRegister
		|> expect(:lookup_code, fn(_) -> neighbour end)
		|> expect(:check_active, fn(_) -> true end)


		Station.send_to_stn(pid, itinerary)

		# Query should not be forwarded to neighbour
		assert_receive({:itinerary_received,^proper_itinerary})
	end

	# Test 10

	test "Terminated queries are handed over to query collector with correct itinerary" do
		stationState = %StationStruct{loc_vars: %{"delay": 0.38,
			"congestion": "low", "disturbance": "no"},
			schedule: [%{vehicleID: "100", src_station: 1, mode_of_transport: "bus",
			dst_station: 2, dept_time: 25000, arrival_time: 35000}],
			congestion_low: 4, choose_fn: 1}

		itinerary = [%{qid: "0100", src_station: 0, dst_station: 1, day: 0, arrival_time: 0},
			%{vehicleID: "99", src_station: 0, mode_of_transport: "train",
			dst_station: 1, dept_time: 10000, arrival_time: 20000}]

		proper_itinerary=[%{qid: "0101", src_station: 0, dst_station: 1, day: 0, arrival_time: 0},
			%{vehicleID: "99", src_station: 0, mode_of_transport: "train",
			dst_station: 1, dept_time: 10000, arrival_time: 20000},
			%{vehicleID: "100", src_station: 1, mode_of_transport: "bus",
			dst_station: 2, dept_time: 25000, arrival_time: 35000}]

		test_proc=self()

		MockRegister
		|> expect(:check_active, fn(_,_) -> true end)

		MockCollector
		|> expect(:collect, fn(_,itinerary) -> send(test_proc,
			{:query_received, itinerary}) end)

		{:ok,pid}=start_supervised(Station,[stationState,
			MockRegister, MockCollector])
		Station.send_to_stn(pid, itinerary)

		assert_receive({:query_received, ^proper_itinerary} )
	end

	# Test 11

	# Test to check if the station consumes a given number of
	# streams within a stipulated amount of time.
	test "Consumes rapid stream of mixed input queries" do
		query = [%{qid: "0100", src_station: 0, dst_station: 1, day: 0, arrival_time: 0}]

		stationState = %StationStruct{loc_vars: %{"delay": 0.38,
			"congestion": "low", "disturbance": "no"},
			schedule: [%{vehicleID: "100", src_station: 1, mode_of_transport: "bus",
			dst_station: 2, dept_time: 25000, arrival_time: 35000}],
			congestion_low: 4, choose_fn: 1}


		mock_receive_at_stn= {fn(_,_) -> false end}

		# Start station
		{:ok, pid} = start_supervised(Station,[stationState,
			MockRegister, MockCollector])
		{:ok,mock_pid} = start_supervised(MockStation,mock_receive_at_stn)

		MockRegister
		|> stub(:lookup_code, fn(_) -> mock_pid end)
		|> stub(:check_active, fn(_) ->
			true
			end)

		# Send 1000 queries
		send_message(query, 1000, pid)

		# Sleep for 1000 milliseconds
		:timer.sleep(1000)

		# Check if length of message queue is 0
		{:message_queue_len, queue_len} = :erlang.process_info(pid,
			:message_queue_len)
		assert queue_len == 0

		# Send 10000 queries
		send_message(query, 10000, pid)

		:timer.sleep(1000)

		{:message_queue_len, queue_len} = :erlang.process_info(pid,
			:message_queue_len)
		assert queue_len == 0

		# Send 1000000 queries
		send_message(query, 1000000, pid)

		:timer.sleep(1000)

		{:message_queue_len, queue_len} = :erlang.process_info(pid,
			:message_queue_len)
		assert queue_len == 0
	end

	def send_message(msg, 1, pid) do
		Station.receive_at_src(pid, msg)
	end

	# A function to send 'n' number of messages to given pid
	def send_message(msg, n, pid) do
		Station.receive_at_src(pid, msg)
		send_message(msg, n-1, pid)
	end
 end
