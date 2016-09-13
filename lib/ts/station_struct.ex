defmodule StationStruct do
  defstruct locVars: %{delay: nil, congestionDelay: nil, congestion: nil, disturbance: nil}, schedule: [%{vehicleID: nil, src_station: nil, dst_station: nil, dept_time: nil, arrival_time: nil, mode_of_transport: nil}], station_number: nil, station_name: nil, pid: nil, congestion_low: nil, congestion_high: nil, choose_fn: nil

end

# Struct permitted values:
# delay: float 0.38, congestion: string "none"/"low"/"high", disturbance: string "no"/"yes"
# vehicleID: int 12959, src_station: int 1, dst_station: int 2, dept_time: "03:12:00", arrival_time: "11:32:00", mode_of_transport: string "train"
# station_number: int, station_name: string, pid: string 3.8.1
# congestion_low: 2, congestion_high: 3, choose_fn: 1


# Notes:
# functions called from StationFunctions using arguments passed with values of data in StationStruct
# associated pid stored for each station thread
# arrival and departure times need to reflect periodicity
