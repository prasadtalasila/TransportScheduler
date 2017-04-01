defmodule StationStruct do
	@moduledoc """
	Module defining the data structure used to describe a station
	"""
	defstruct loc_vars: %{delay: nil, congestion_delay: nil, congestion: nil,
	disturbance: nil}, schedule: [%{vehicleID: nil, src_station: nil, dst_station:
	nil, dept_time: nil, arrival_time: nil, mode_of_transport: nil}],
	other_means: [], station_number: nil, station_name: nil, pid: nil,
	congestion_low: 2, congestion_high: 3, choose_fn: 1

end

# Struct permitted values:
# delay: float 0.38, congestion: string "none"/"low"/"high", disturbance: string
# "no"/"yes"
# vehicleID: int 12959, src_station: int 1, dst_station: int 2, dept_time:
# "03:12:00", arrival_time: "11:32:00", mode_of_transport: string "train"
# station_number: int, station_name: string, pid: string 3.8.1
# congestion_low: 2, congestion_high: 3, choose_fn: 1
