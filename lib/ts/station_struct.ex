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
