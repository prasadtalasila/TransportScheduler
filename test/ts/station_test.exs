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

  end


end


# Use demo station values: 
# ss = %StationStruct{locVars: %{"delay": 0.38, "congestion": "low", "disturbance": "no"}, schedule: [%{vehicleID: 12959, src_station: 1, dst_station: 2, dept_time: nil, arrival_time: nil, mode_of_transport: "train"}], station_number: 1, station_name: "VascoStation", congestion_low: 2, congestion_high: 3}
