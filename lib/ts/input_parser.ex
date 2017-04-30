defmodule InputParser do
	@moduledoc """
	Module to store data from input files in the defined station structure.
	Files stations.txt, schedule.txt, OMT.txt, local_variables.txt store data
	of transit stations and connections. These are read into appropriate maps
	for storing in corresponding Station processes.

	Uses GenServer.
	"""
	use GenServer

	# Client-side functions

	@doc """
	Starts a GenServer InputParser process linked to the current process.

	This is often used to start the GenServer as part of a supervision tree.

	Once the server is started, the `init/1` function of the given module is
	called with args as its	arguments to initialize the server.

	### Parameters
	module

	args

	### Return values
	If the server is successfully created and initialized, this function returns
	{:ok, pid}, where pid is the PID of the server. If a process with the specified
	server name already exists, this function returns {:error, {:already_started,
	pid}} with the PID of that process.

	If the `init/1` callback fails with reason, this function returns {:error,
	reason}. Otherwise, if it returns {:stop, reason} or :ignore, the process is
	terminated and this function returns {:error, reason} or :ignore, respectively.
	"""
	def start_link do
		GenServer.start_link(__MODULE__, :ok)
	end

	@doc """
	Returns map of station cities to station codes, taken from InputParser process
	when its pid is known.

	### Parameters
	ip_pid

	### Return values
	Returns {:reply, station_map, state}.
	"""
	def get_station_map(pid) do
		GenServer.call(pid, :get_station_map)
	end

	@doc """
	Returns map of source station codes to schedule list of vehicles from that
	source station, taken from InputParser process when its pid is known.

	### Parameters
	ip_pid

	### Return values
	Returns {:reply, schedules_map, state}.
	"""
	def get_schedules(pid) do
		GenServer.call(pid, :get_schedules)
	end

	@doc """
	Return schedule list of vehicles from source station having given code, taken
	from InputParser process when its pid is known.

	### Parameters
	ip_pid

	station_code

	### Return values
	Returns {:reply, schedule_list, state}.
	"""
	def get_schedule(pid, code) do
		GenServer.call(pid, {:get_schedule, code})
	end

	@doc """
	Returns schedule list of other means connections from source station having
	given code, taken from InputParser process when its pid is known.

	### Parameters
	ip_pid

	station_code

	### Return values
	Returns {:reply, OMT_list, state}.
	"""
	def get_other_means(pid, code) do
		GenServer.call(pid, {:get_other_means, code})
	end

	@doc """
	Return map of local variables from source station having given code, taken
	from InputParser process when its pid is known.

	### Parameters
	ip_pid

	station_code

	### Return values
	Returns {:reply, loc_var_map, state}.
	"""
	def get_local_variables(pid, code) do
		GenServer.call(pid, {:get_loc_vars, code})
	end

	@doc """
	Returns station code from map using station city as key, taken from
	InputParser process when its pid is known.

	### Parameters
	ip_pid

	station_name

	### Return values
	Returns {:reply, station_code, state}.
	"""
	def get_city_code(pid, city) do
		GenServer.call(pid, {:get_city_code, city})
	end

	@doc """
	Return Station struct having local variable and schedule information for
	a given station city, taken from InputParser process when its pid is known.

	### Parameters
	ip_pid

	station_name

	### Return values
	Returns station struct of the form `%{loc_vars_map, schedule_list,
	other_means_list, station_code, station_city}`.
	"""
	def get_station_struct(pid, city) do
		stn_struct=%StationStruct{}
		code=get_city_code(pid, city)
		%{stn_struct|loc_vars: Map.merge(stn_struct.loc_vars,
			get_local_variables(pid, code)), schedule: get_schedule(pid, code),
			other_means: get_other_means(pid, code), station_number: code,
			station_name: city}
	end

	@doc """
	Stops the InputParser process with the given reason.

	### Parameters
	ip_pid

	### Return values
	The `terminate/2` callback of the given server will be invoked before
	exiting. This function returns :ok if the server terminates with the
	given reason; if it terminates with another reason, the call exits.
	"""
	def stop(pid) do
		GenServer.stop(pid, :normal, 100)
	end

	# Server-side callback functions

	def init(:ok) do
		# values are read from input data files
		station_map=obtain_stations()
		schedule=obtain_schedules()
		loc_var_map=obtain_loc_var_map()
		other_means=obtain_other_means()
		{:ok, {station_map, schedule, loc_var_map, other_means}}
	end

	def handle_call(:get_station_map, _from, {station_map, _, _, _}=state) do
		# Map of station name and station code returned
		{:reply, station_map, state}
	end

	def handle_call(:get_schedules, _from, {_, schedule, _, _}=state) do
		# schedules for a station are returned
		{:reply, schedule, state}
	end

	def handle_call({:get_loc_vars, code}, _from, {_, _, loc_var_map, _}=state) do
		# local variables for a station are returned
		{:reply, Map.fetch!(loc_var_map, code), state}
	end

	def handle_call({:get_city_code, city}, _from, {station_map, _, _, _}=state)
	do
		 # station code given station name is returned
	 {:reply, Map.fetch!(station_map, city), state}
	end

	def handle_call({:get_schedule, code}, _from, {_, schedule, _, _}=state) do
		# schedules for a station and destination are returned
		{:reply, Keyword.get_values(schedule, String.to_atom(Integer.to_string(code)
			)), state}
	end

	def handle_call({:get_other_means, code}, _from, {_, _, _, other_means}=state)
	do
		# other means table for a station is returned
		x=Keyword.get_values(other_means, String.to_atom(Integer.to_string(code)))
		{:reply, x, state}
	end

	def terminate(reason, state) do
		super(reason, state)
	end

	# Helper functions

	# Obtains Map of stations
	def obtain_stations do
		station_map=Map.new
		{_, file}=open_file("data/stations.txt")
		#n = IO.binread file, [:line] |> String.trim |> String.to_integer
		n=2264
		obtain_station(file, n, station_map)
	end

	# Obtains Map of schedules
	def obtain_schedules do
		schedule=Keyword.new
		{_, file}=open_file("data/schedule.txt")
		#n = IO.binread file, [:line] |> String.trim |> String.to_integer
		n=56_555
		obtain_schedule(file, n, schedule)
	end

	# Obtains list of other means transport
	def obtain_other_means do
		other_means=Keyword.new
		{_, file}=open_file("data/OMT.txt")
		n=151
		obtain_other_mean(file, n, other_means)
	end

	# Obtains Map of local variables
	def obtain_loc_var_map do
		loc_var_map=Map.new
		{_, file}=open_file("data/local_variables.txt")
		#n = IO.binread file, [:line] |> String.trim |> String.to_integer
		n=2264
		obtain_loc_vars(file, n, loc_var_map)
	end

	# Opens the file specified by 'filename' parameter.
	defp open_file(filename) do
		File.open(filename, [:read, :binary])
	end

	# 'Loops' through the n entries of the 'stations.txt' file and saves
	# The city name and city code as a (key, value) tuples in a map.
	defp obtain_station(file, n, station_map) when n>0 do
		[code|city]=file|>IO.binread(:line)|>String.trim()|>String.split(" ", parts:
		2)
		city=List.to_string(city)
		code=String.to_integer(code)
		station_map=Map.put(station_map, city, code)
		obtain_station(file, n-1, station_map)
	end

	# Closes the file after reading data of n stations.
	defp obtain_station(file, _, station_map) do
		close_file(file)
		station_map
	end

	# 'Loops' through the n entries of the 'schedule.txt' file and saves
	# The variables as entries in a data structure called Keyword.
	defp obtain_schedule(file, n, schedule) when n>0 do
		[vehicle_id|tail]=file|>IO.binread(:line)|>String.trim|>String.split(" ",
			parts: 6)
		[src_station|tail]=tail
		src_station=String.to_integer(src_station)
		[dst_station|tail]=tail
		dst_station=String.to_integer(dst_station)
		[dept_time|tail]=tail
		dept_time=String.to_integer(dept_time)
		[arrival_time|mode_of_transport]=tail
		mode_of_transport=List.to_string(mode_of_transport)
		arrival_time=String.to_integer(arrival_time)
		sched=Map.new|>Map.put(:vehicleID, vehicle_id)|>
		Map.put(:src_station, src_station)|>Map.put(:dst_station, dst_station)|>
		Map.put(:dept_time, dept_time)|>Map.put(:arrival_time, arrival_time)|>
		Map.put(:mode_of_transport, mode_of_transport)
		schedule=schedule|>Enum.into([{src_station|>Integer.to_string|>
			String.to_atom, sched}])
		obtain_schedule(file, n-1, schedule)
	end

	# Closes the file after reading schedules of n stations.
	defp obtain_schedule(file, _, schedule) do
		close_file(file)
		schedule
	end

	# 'Loops' through the n entries of the 'OMT.txt' file and saves
	# The variables as entries in a data structure called Keyword.
	defp obtain_other_mean(file, n, other_means) when n>0 do
		[src_station|tail]=file|>IO.binread(:line)|>String.trim|>
		String.split(" ", parts: 3)
		src_station=String.to_integer(src_station)
		[dst_station | travel_time]=tail
		dst_station=String.to_integer(dst_station)
		travel_time=travel_time|>List.to_string|>String.to_integer
		sched=Map.new|>Map.put(:src_station, src_station)|>
		Map.put(:dst_station, dst_station)|>Map.put(:travel_time, travel_time)
		other_means=other_means|>Enum.into([{src_station|>Integer.to_string|>
			String.to_atom, sched}])
		obtain_other_mean(file, n-1, other_means)
	end

	# Closes the file after reading other means of n stations.
	defp obtain_other_mean(file, _, other_means) do
		close_file(file)
		other_means
	end

	# 'Loops' through the n entries of the 'local_variables.txt' file and saves
	# The local variables as (key, value) tuples in a map.
	defp obtain_loc_vars(file, n, loc_var_map) when n>0 do
		[station_code|tail]=file|>IO.binread(:line)|>String.trim|>String.split(" ",
			parts: 7)
		station_code=String.to_integer(station_code)
		[local_var1|tail]=tail
		local_var1=String.to_atom(local_var1)
		[val1|tail]=tail
		val1=String.to_float(val1)
		[local_var2 | tail]=tail
		local_var2=String.to_atom(local_var2)
		[val2|tail]=tail
		[local_var3|val3]=tail
		local_var3=String.to_atom(local_var3)
		val3=List.to_string(val3)
		vals=Map.new|>Map.put(local_var1, val1)|>Map.put(local_var2, val2)|>
		Map.put(local_var3, val3)
		loc_var_map=Map.put(loc_var_map, station_code, vals)
		obtain_loc_vars(file, n-1, loc_var_map)
	end

	# Closes the file after reading the local variables values of n stations.
	defp obtain_loc_vars(file, _, loc_var_map) do
		close_file(file)
		loc_var_map
	end

	# Closes the file handle specified by 'file_handle' parameter.
	defp close_file(file_handle) do
		File.close(file_handle)
	end
end
