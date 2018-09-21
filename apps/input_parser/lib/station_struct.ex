defmodule StationStruct do
	@moduledoc """
	Module defining the data structure used to describe a station, with local
	variables, schedule, other means, and additional information fields such
	as station code, station city name, station process pid.
	The structure looks as follows:
	`%StationStruct{loc_vars: %{delay, congestion_delay, congestion,
	disturbance},
	schedule: [%{vehicleID, src_station, dst_station, dept_time, arrival_time,
	mode_of_transport}],
	other_means,
	station_number,
	station_name,
	pid,
	congestion_low,
	congestion_high,
	choose_fn}`
	The map fields are described below:
	loc_vars - holds a map of local variable values:
	- delay : value for average delay in seconds at the station
	- congestion_delay : computed value from delay and congestion
	- congestion : "none", "low", or "high"
	- disturbance : "yes" or "no"
	schedule - holds a list of maps of connections to neighbouring stations
	given this source station, with each map `%{vehicleID, src_station,
	dst_station, dept_time, arrival_time, mode_of_transport}`
	having:
	- vehicleID : string vehicle ID
	- src_station : source station code
	- dst_station : destination station code
	- dept_time : time of departure from source
	- arrival_time : tim of arrival at destination
	- mode_of_transport : "train" or "bus" or "flight"
	other_means - holds a list of maps of connections to neighbouring stations
	given this source station, with each map `%{vehicleID, src_station,
	dst_station, dept_time, arrival_time, mode_of_transport}`
	having:
	- vehicleID : string vehicle ID
	- src_station : source station code
	- dst_station : destination station code
	- dept_time : time of departure from source
	- arrival_time : tim of arrival at destination
	- mode_of_transport : "Other Means"
	station_number - station code
	station_name - station city name
	pid - station process pid
	congestion_low - factor value if congestion is low
	congestion_high - factor value if congestion is high
	choose_fn - value (currently 1, 2, or 3)  to decide choice of function
	to compute final congestion delay
	"""
	defstruct loc_vars: %{delay: nil, congestion_delay: nil, congestion: nil,
	disturbance: nil}, schedule: [%{vehicleID: nil, src_station: nil, dst_station:
	nil, dept_time: nil, arrival_time: nil, mode_of_transport: nil}],
	other_means: [], station_number: nil, station_name: nil, pid: nil,
	congestion_low: 2, congestion_high: 3, choose_fn: 1

end