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
		set_mox_global()
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
		assert Station.get_state(station) == :ready
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
		# {:ok, station} = start_supervised(Station,[stationState,
		# 	MockRegister, MockCollector])

		{:ok, station} = Station.start_link([stationState,
			MockRegister, MockCollector])

		# Check to see if change has taken place
		# assert Station.get_vars(station).loc_vars.congestion_delay == 0.38 * 4

		# Update state again
		Station.update(station, %StationStruct{loc_vars: %{"delay": 0.0,
			"congestion": "none", "disturbance": "no"},
			schedule: [], station_name: "Panjim", choose_fn: 1})

		# Check to see if update has taken place
		assert Station.get_vars(station).loc_vars.disturbance == "no"
		# assert Station.get_vars(station).loc_vars.congestion_delay == 0.0
		assert Station.get_vars(station).station_name == "Panjim"
	end
end
