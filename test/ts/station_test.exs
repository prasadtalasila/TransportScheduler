# Module to test Station
# Successfully creates new station process with associated FSM and updates local variable values

defmodule StationTest do
  use ExUnit.Case 
  
  test "station" do
    
    # Start the server
    {:ok, station} = Station.start_link()

    Station.Update.update(%Station{pid: station}, ss = %StationStruct{locVars: %{"delay": 0.38, "congestion": "low", "disturbance": "no"}, schedule: [], congestion_low: 4, choose_fn: 1})

    assert Station.get_vars(station).locVars.delay == 0.38
    assert Station.get_vars(station).locVars.congestionDelay == 0.38*4

  end

  test "select itinerary" do
    {:ok, station} = Station.start_link()

    Station.Update.update(%Station{pid: station}, ss = %StationStruct{locVars: %{"delay": 0.38, "congestion": "low", "disturbance": "no", "congestion_low": 4, "choose_fn": 1}, schedule: [%{vehicleID: 1111, src_station: 1, dst_station: 2, dept_time: "07:12:00", arrival_time: "16:32:00", mode_of_transport: "train"}, %{vehicleID: 2222, src_station: 1, dst_station: 2, dept_time: "13:12:00", arrival_time: "14:32:00", mode_of_transport: "train"}, %{vehicleID: 3333, src_station: 1, dst_station: 2, dept_time: "03:12:00", arrival_time: "10:32:00", mode_of_transport: "train"}, %{vehicleID: 4444, src_station: 1, dst_station: 2, dept_time: "19:12:00", arrival_time: "20:32:00", mode_of_transport: "train"}]})
    
    time = "04:42:00"
    
    #IO.puts Station.get_vars(station).schedule
    #IO.puts Station.check_neighbours(station, time)
    assert Station.check_neighbours(station, time) == [%{arrival_time: "14:32:00", dept_time: "13:12:00", dst_station: 2, mode_of_transport: "train", src_station: 1, vehicleID: 2222}, %{arrival_time: "16:32:00", dept_time: "07:12:00", dst_station: 2, mode_of_transport: "train", src_station: 1, vehicleID: 1111}, %{arrival_time: "20:32:00", dept_time: "19:12:00", dst_station: 2, mode_of_transport: "train", src_station: 1, vehicleID: 4444}]
  end

end


# Use demo station values: 
# ss = %StationStruct{locVars: %{"delay": 0.38, "congestion": "low", "disturbance": "no"}, schedule: [%{vehicleID: 12959, src_station: 1, dst_station: 2, dept_time: nil, arrival_time: nil, mode_of_transport: "train"}], station_number: 1, station_name: "VascoStation", congestion_low: 2, congestion_high: 3}
