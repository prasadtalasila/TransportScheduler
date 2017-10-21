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

	# Test to see if the given state is stored by updating 
	# some variables
	test "stores the given state" do
		# Start the server
		{:ok, station} = Station.start_link

		# Update variables in station
		Station.update(station, %StationStruct{loc_vars: %{"delay": 0.38,
			"congestion": "low", "disturbance": "no"},
			schedule: [], congestion_low: 4, choose_fn: 1})

		# Verify values from StationStruct
		assert Station.get_vars(station).loc_vars.delay == 0.38
		assert Station.get_vars(station).loc_vars.congestion_delay == 0.38 * 4
		assert Station.get_state(station) == :delay
	end

	# Test to see if data can be retrieved from the station correctly
	test "retrieving the given state" do
		# Start the server
		{:ok, station} = Station.start_link

		# Update variables in station
		Station.update(station, %StationStruct{loc_vars: %{"delay": 0.12,
			"congestion": "low", "disturbance": "no"},
			schedule: [], station_number: 1710, 
			station_name: "Mumbai", congestion_low: 3, choose_fn: 2})

		# Retrieve values from loc_vars
		assert Station.get_vars(station).loc_vars.delay == 0.12l
		assert Station.get_vars(station).loc_vars.congestion == "low"
		assert Station.get_vars(station).loc_vars.disturbance == "no"

		# Retrieve other values from StationStruct
		assert Station.get_vars(station).station_number == 1710
		assert Station.get_vars(station).station_name == "Mumbai"
		assert Station.get_vars(station).congestion_delay == 0.12 * 3 + 0.2
	end

	# Test to see if the state gets updated once new variable 
	# values are given
	test "updating the given state" do
		# Start the server
		{:ok, station} = Station.start_link

		# Update variables in station
		Station.update(station, %StationStruct{loc_vars: %{"delay": 0.38,
			"congestion": "low", "disturbance": "no"},
			schedule: [], congestion_low: 4, choose_fn: 1})

		# Check to see if change has taken place
		assert Station.get_vars(station).loc_vars.congestion_delay == 0.38 * 4

		# Update state again
		Station.update(station, %StationStruct{loc_vars: %{"delay": 0.0,
			"congestion": "none", "disturbance": "no"},
			schedule: [], station_name: "Panjim", choose_fn: 1})

		# Check to see if update has taken place
		assert Station.get_vars(station).loc_vars.disturbance == "no"
		assert Station.get_vars(station).loc_vars.congestion_delay == 0.0
		assert Station.get_vars(station).station_name == "Panjim"
	end

	test "Receive a itinerary search query" do

		# Set function parameters to arbitrary values.
		# Any errors due to invalid values do not matter as they will come into
		# effect only after the station has received the query.
		query=:unassigned
		stationState=:unassigned
		test_proc=self()

		#start station
		{:ok,pid}=start_supervised(Station,[stationState, 
			MockRegister, MockCollector])

		MockRegister
		|> expect(:check_active,
			fn(_) -> send(test_proc, :query_received)
			false
			end)

		#Send query to station
		Station.receive_at_src(pid, query)

		#assert that the station has received a message :query_received
		assert_receive(:query_received)

    	#IO.inspect(some_var)

	end

	test "Send completed search query to neighbours" do
		stationState=:unassigned
		neighbourState=:unassigned
		itinerary=:unassigned
		test_proc=self()

		{:ok,pid}=start_supervised(Station,[stationState, 
			MockRegister, MockCollector])
		{:ok,neighbour}=start_supervised(Station,[neighbourState, 
			MockRegister, MockCollector])

		MockRegister
		|> expect(:lookup_code, fn(_) -> neighbour end)
		|> expect(:check_active, fn(_) -> true end)
		|> expect(:check_active,
			fn(_) -> send(test_proc, :query_received)
			false
			end)

		Station.send_to_stn(self() , pid, itinerary)

		assert_receive :query_received
		#IO.inspect(some_var)

	end

	test "Does not forward itineraries with potential self-loops" do
		stationState=:unassigned
		neighbourState=:unassigned
		itinerary=:unassigned
		test_proc=self()

		{:ok,pid}=start_supervised(Station,[stationState, 
			MockRegister, MockCollector])
		{:ok,neighbour}=start_supervised(Station,[neighbourState, 
			MockRegister, MockCollector])

		MockRegister
		|> expect(:lookup_code, fn(_) -> neighbour end)
		|> expect(:check_active, fn(_) -> true end)
		|> expect(:check_active,
			fn(_) -> send(test_proc, :query_with_selfloop_forwarded)
			false
			end)

		Station.send_to_stn(self() , pid, itinerary)

		# Query should not be forwarded to neighbour
		refute_receive(:query_with_selfloop_forwarded)

	end

	test "Does not forward stale queries" do
		stationState=:unassigned
		neighbourState=:unassigned
		itinerary=:unassigned
		test_proc=self()

		{:ok,pid}=start_supervised(Station,[stationState, 
			MockRegister, MockCollector])
		{:ok,neighbour}=start_supervised(Station,[neighbourState, 
			MockRegister, MockCollector])

		MockRegister
		|> expect(:lookup_code, fn(_) -> neighbour end)
		|> expect(:check_active, fn(_) -> false end)
		|> expect(:check_active,
			fn(_) -> send(test_proc, :stale_query_forwarded)
			false
			end)

		Station.send_to_stn(self() , pid, itinerary)

		# Query should not be forwarded to neighbour
		refute_receive(:stale_query_forwarded)


	end

	test "Incorrectly received queries are discarded" do
		stationState=:unassigned
		neighbourState=:unassigned
		itinerary=:unassigned
		test_proc=self()

		{:ok,pid}=start_supervised(Station,[stationState, 
			MockRegister, MockCollector])
		{:ok,neighbour}=start_supervised(Station,[neighbourState, 
			MockRegister, MockCollector])

		MockRegister
		|> expect(:lookup_code, fn(_) -> neighbour end)
		|> expect(:check_active, fn(_) -> true end)
		|> expect(:check_active,
			fn(_) -> send(test_proc, :incorrect_query_forwarded)
			false
			end)

		Station.send_to_stn(self() , pid, itinerary)

		# Query should not be forwarded to neighbour
		refute_receive(:incorrect_query_forwarded)


	end

	test "The correct itinerary is forwarded to the next station" do
		stationState=:unassigned
		neighbourState=:unassigned
		itinerary=:unassigned


		{:ok,pid}=start_supervised(Station,[stationState, 
			MockRegister, MockCollector])
		{:ok,neighbour}=start_supervised(Station,[neighbourState, 
			MockRegister, MockCollector])

		MockRegister
		|> expect(:lookup_code, fn(_) -> neighbour end)
		|> expect(:check_active, fn(_) -> true end)

		:erlang.trace(neighbour, true, [:receive])
		Station.send_to_stn(self() , pid, itinerary)

		# Query should not be forwarded to neighbour
		assert_receive({:trace, ^neighbour, :receive, :unassigned_correct_itinerary})


	end

	test "Terminated queries are handed over to query collector with correct itinerary" do
		stationState=:unassigned
		itinerary=:unassigned
		test_proc=self()

		MockRegister
		|> expect(:check_active, fn(_) -> true end)

		MockCollector
		|> expect(:collect, fn(_) -> send(test_proc, 
			{:query_received, :proper_itinerary}) end)

		{:ok,pid}=start_supervised(Station,[stationState, 
			MockRegister, MockCollector])
		Station.send_to_stn(self() , pid, itinerary)

		assert_receive({:query_received, :proper_itinerary} )
	end

	# Test to check if the station consumes a given number of
	# streams within a stipulated amount of time.
	test "Consumes rapid stream of mixed input queries" do
		query = :unassigned
		stationState = :unassigned
		test_proc = self()

		# Start station
		{:ok, pid} = start_supervised(Station,[stationState, 
			MockRegister, MockCollector])

		MockRegister
		|> expect(:check_active,
			fn(_) -> send(test_proc, :query_received)
			false
			end)

		# Send 1000 queries
		send_message(query, 1000, pid)

		# Sleep for 1000 milliseconds
		:timer.sleep(1000)

		# Check if length of message queue is 0
		{:message_queue_len, queue_len} = :erlang.process_info(test_proc, 
			:message_queue_len)
		assert queue_len == 0

		# Send 10000 queries
		send_message(query, 10000, pid)

		:timer.sleep(1000)

		{:message_queue_len, queue_len} = :erlang.process_info(test_proc, 
			:message_queue_len)
		assert queue_len == 0

		# Send 1000000 queries
		send_message(query, 1000000, pid)

		:timer.sleep(1000)

		{:message_queue_len, queue_len} = :erlang.process_info(test_proc, 
			:message_queue_len)
		assert queue_len == 0		
	end

	# A function to send 'n' number of messages to given pid 
	def send_message(msg, n, pid) do
		send(pid, msg)
		send_message(msg, n-1, pid)
	end

	def send_message(msg, 1, pid) do
		send(pid, msg)
	end
end
