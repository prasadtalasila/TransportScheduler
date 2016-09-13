# Module to test Station
# Successfully creates new station process with associated FSM and updates local variable values

defmodule StationTest do
  use ExUnit.Case 
  
  test "station" do
    
    # Start the server
    {:ok, station} = Station.start_link()

    Station.update(station, ss = %StationStruct{locVars: %{"delay": 0.38, "congestion": "low", "disturbance": "no"}, schedule: [], congestion_low: 4, choose_fn: 1})

    assert Station.get_vars(station).locVars.delay == 0.38
    assert Station.get_vars(station).locVars.congestionDelay == 0.38*4

    # sort schedule according to Enum.sort_by(schedule, &(schedule.dept_time))
    # implement robust pattern check of string passed as function for congestions
  end

end
