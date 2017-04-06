defmodule StationTest do
	@moduledoc """
	Module to test Station
	Create new station process with associated FSM and updates local variable
	values
	"""
	use ExUnit.Case

	test "Start and update a new Station process" do
		# Start the server
		{:ok, station}=Station.start_link
		Station.update(station, %StationStruct{loc_vars: %{"delay": 0.38,
			"congestion": "low", "disturbance": "no"},
			schedule: [], congestion_low: 4, choose_fn: 1})
		assert Station.get_vars(station).loc_vars.delay==0.38
		assert Station.get_vars(station).loc_vars.congestion_delay==0.38*4
		assert Station.get_state(station)==:delay
	end
end
