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

	test "Receive a itinerary search query" do

		#set function parameters to arbitrary values
		#Any errors due to invalid values do not matter as they will come into
		#effect only after the station has received the query.
		query=:unassigned
		stationState=:unassigned
		test_proc=self()

		#start station
		{:ok,pid}=start_supervised(Station,[stationState, MockRegister, MockCollector])

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

		{:ok,pid}=start_supervised(Station,[stationState, MockRegister, MockCollector])
		{:ok,neighbour}=start_supervised(Station,[neighbourState, MockRegister, MockCollector])

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

		{:ok,pid}=start_supervised(Station,[stationState, MockRegister, MockCollector])
		{:ok,neighbour}=start_supervised(Station,[neighbourState, MockRegister, MockCollector])

		MockRegister
		|> expect(:lookup_code, fn(_) -> neighbour end)
		|> expect(:check_active, fn(_) -> true end)
		|> expect(:check_active,
			fn(_) -> send(test_proc, :query_with_selfloop_forwarded)
			false
			end)

		Station.send_to_stn(self() , pid, itinerary)

		#Query should not be forwarded to neighbour
		refute_receive(:query_with_selfloop_forwarded)

	end

	test "Does not forward stale queries" do
		stationState=:unassigned
		neighbourState=:unassigned
		itinerary=:unassigned
		test_proc=self()

		{:ok,pid}=start_supervised(Station,[stationState, MockRegister, MockCollector])
		{:ok,neighbour}=start_supervised(Station,[neighbourState, MockRegister, MockCollector])

		MockRegister
		|> expect(:lookup_code, fn(_) -> neighbour end)
		|> expect(:check_active, fn(_) -> false end)
		|> expect(:check_active,
			fn(_) -> send(test_proc, :stale_query_forwarded)
			false
			end)

		Station.send_to_stn(self() , pid, itinerary)

		#query should not be forwarded to neighbour
		refute_receive(:stale_query_forwarded)


	end


	test "Incorrectly received queries are discarded" do
		stationState=:unassigned
		neighbourState=:unassigned
		itinerary=:unassigned
		test_proc=self()

		{:ok,pid}=start_supervised(Station,[stationState, MockRegister, MockCollector])
		{:ok,neighbour}=start_supervised(Station,[neighbourState, MockRegister, MockCollector])

		MockRegister
		|> expect(:lookup_code, fn(_) -> neighbour end)
		|> expect(:check_active, fn(_) -> true end)
		|> expect(:check_active,
			fn(_) -> send(test_proc, :incorrect_query_forwarded)
			false
			end)

		Station.send_to_stn(self() , pid, itinerary)

		#query should not be forwarded to neighbour
		refute_receive(:incorrect_query_forwarded)


	end

	test "The correct itinerary is forwarded to the nex station" do
		stationState=:unassigned
		neighbourState=:unassigned
		itinerary=:unassigned


		{:ok,pid}=start_supervised(Station,[stationState, MockRegister, MockCollector])
		{:ok,neighbour}=start_supervised(Station,[neighbourState, MockRegister, MockCollector])

		MockRegister
		|> expect(:lookup_code, fn(_) -> neighbour end)
		|> expect(:check_active, fn(_) -> true end)

		:erlang.trace(neighbour, true, [:receive])
		Station.send_to_stn(self() , pid, itinerary)

		#query should not be forwarded to neighbour
		assert_receive({:trace, ^neighbour, :receive, :unassigned_correct_itinerary})


	end

	test "Terminated queries are handed over to query collector with correct itinerary" do
		stationState=:unassigned
		itinerary=:unassigned
		test_proc=self()

		MockRegister
		|> expect(:check_active, fn(_) -> true end)

		MockCollector
		|> expect(:collect, fn(_) -> send(test_proc, {:query_received, :proper_itinerary}) end)

		{:ok,pid}=start_supervised(Station,[stationState, MockRegister, MockCollector])
		Station.send_to_stn(self() , pid, itinerary)

		assert_receive({:query_received, :proper_itinerary} )
	end

end
