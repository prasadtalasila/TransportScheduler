defmodule StationStruct do
  defstruct locVars: %{delay: nil, congestionDelay: nil, congestion: nil, disturbance: nil},
    schedule: [%{vehicleID: nil, src_station: nil, dst_station: nil, dept_time: nil, arrival_time: nil, mode_of_transport: nil}],
    congestion_low: "delay * 2", congestion_high: "delay * 3",
    station_number: 0, station_name: "none", pid: "0.0.0"
end
