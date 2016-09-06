defmodule StationContructor do
  def new(stationName) do
    #InputParser
    ss = %StationStruct{locVars: %{"delay": 0.38, "congestion": "low", "disturbance": "no"}, schedule: [%{vehicleID: 12959, src_station: 1, dst_station: 2, dept_time: nil, arrival_time: nil, mode_of_transport: "train"}], station_number: 1, station_name: "VascoStation", congestion_low: 2, congestion_high: 3}
    #get PID station
    #Station.update
  end
end
