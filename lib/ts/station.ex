defmodule Station do
	@moduledoc """
	Module to create a transit station node. The station process pid can be used to retrieve station struct 
	values such as local variables and schedule. It can also be used to handle local variable updates.

	Uses GenStateMachine.
	"""
	use GenStateMachine, async: true

	@doc """
	Starts a GenStateMachine Station process linked to the current process.

	This is often used to start the GenStateMachine as part of a supervision tree.

	Once the server is started, the `init/1` function of the given module is called with args as its 
	arguments to initialize the server.   
	
	### Parameters
	module

	args   
	
	### Return values
	If the server is successfully created and initialized, this function returns {:ok, pid}, where pid
	is the PID of the server. If a process with the specified server name already exists, this function
	returns {:error, {:already_started, pid}} with the PID of that process.

	If the `init/1` callback fails with reason, this function returns {:error, reason}. Otherwise, if 
	it returns {:stop, reason} or :ignore, the process is terminated and this function returns
	{:error, reason} or :ignore, respectively.
	"""
	def start_link do
		GenStateMachine.start_link(Station, {:nodata, nil})
	end

	# Client-side getter and setter functions

	@doc """
	Updates station struct values by replacing with new struct composed of the new values for the station,
	and update the state of the station FSM.
	
	### Parameters
	station_pid

	station_struct

	### Return values
	Returns {:next_state, next_state, new_vars}.
	"""
	def update(station,  %StationStruct{}=new_vars) do
		GenStateMachine.cast(station, {:update, new_vars})
	end

	@doc """
	Retrieves station struct local variable values given the station pid.
	
	### Parameters
	station_pid   

	### Return values
	{:next_state, state, vars, [{:reply, from, vars}]}.
	"""
	def get_vars(station) do
		GenStateMachine.call(station, :get_vars)
	end

	@doc """
	Retrieves station struct state value given the station pid.
	
	### Parameters
	station_pid   

	### Return values
	Returns {:next_state, state, vars, [{:reply, from, state}]}.
	"""
	def get_state(station) do
		GenStateMachine.call(station, :get_state)
	end

	# Client-side message-passing functions

	@doc """
	Receives a query encoded in itinerary from NC at source station. The pid of NC and source station
	must be known.
	
	### Parameters
	nc_pid

	src_station_pid
   
	itinerary - in the form of a map `%{vehicleID, src_station, dst_station, dept_time, arrival_time, 
	mode_of_transport}`

	### Return values
	Returns {:ok}.
	"""
	def receive_at_src(nc, src, itinerary) do
		GenStateMachine.cast(src, {:receive_at_src, nc, src, itinerary})
	end

	@doc """
	Sends query from a source station to the neighbouring station and append to itinerary built upto this
	point, ie, upto source station. The pid of NC, source station, and destination station must be known.
	
	### Parameters
	nc_pid

	src_station_pid

	dst_station_pid

	itinerary - in the form of a map `%{vehicleID, src_station, dst_station, dept_time, arrival_time, 
	mode_of_transport}`

	### Return values
	Returns {:ok}
	"""
	def send_to_stn(nc, src, dst, itinerary) do
		GenStateMachine.cast(dst, {:receive_at_stn, nc, src, itinerary})
	end

	@doc """
	Checks if neighbouring station is valid, ie, that it does not result in a looping itinerary. The potential new destination to be added to the itinerary path is compared with all stations already in the itinerary upto this point to decide whether a loop is being formed.

	### Parameters   
	dst_station_pid

	itinerary - in the form of a map `%{vehicleID, src_station, dst_station, dept_time, arrival_time, 
	mode_of_transport}`

	### Return values
	Returns true or false.
	"""
	def check_dest(dst, itinerary) do
		[_|tail]=itinerary
		dest_list=Enum.map(tail, fn (x)->x[:dst_station] end)
		!Enum.member?(dest_list, dst)
	end

	@doc """
	Lists all valid neighbouring stations given a station and arrival time at that station. This takes
	care of overnight journey arrival time modifications. It also adds other means connections to the 
	list of all possible connections to neighbouring stations. If a neighbour is valid based on
	`check_dest/2`, it is added to the list.

	### Parameters   
	schedule - in the form of a list of maps `%{vehicleID, src_station, dst_station, dept_time,
	arrival_time, mode_of_transport}`

	other_means - in the form of a similar list with mode_of_transport: "Other Means"

	time - time of arrival at station

	itinerary - in the form of list of maps `%{vehicleID, src_station, dst_station, dept_time, arrival_time, 
	mode_of_transport}`

	### Return values
	Returns list of connections to valid neighbouring stations, each in the form of a map `%{vehicleID, 
	src_station, dst_station, dept_time, arrival_time, mode_of_transport}`.
	"""
	def check_neighbours(schedule, other_means, time, itinerary) do
		# schedule is filtered to reject neighbours with departure time earlier
		# than arrival time at the station for the current itinerary
		time=if time>86_400 do
			time-86_400
		else
			time
		end
		[query]=Enum.take(itinerary, 1)
		neighbour_list=Enum.filter(schedule, fn(x)->x.dept_time>time&&
			check_dest(x.dst_station, itinerary)&&(query.day*86_400+x.arrival_time)<=
			query.end_time end)
		possible_walks=Enum.filter(other_means,
			fn(x)->check_dest(x.dst_station, itinerary) end)
		list=for x<-possible_walks do
			%{vehicleID: "OM", src_station: x.src_station, dst_station:
			x.dst_station, dept_time: time, arrival_time: time+x.travel_time,
			mode_of_transport: "Other Means"}
		end
		list=Enum.filter(list, fn(x)->(query.day*86_400+x.arrival_time)<=
			query.end_time end)
		List.flatten(list, neighbour_list)
	end

	@doc """
	This function passes queries through the network to build the final itinerary. The connection that
	is required from the schedule list to reach this station from the source station is added to the
	itinerary path. This resulting itinerary is passed along itinerary to neighbouring stations from a
	given source station. If the neighbouring station happens to be the destination station required in
	the query, then the function passes the final itinerary directly to the Query Collector and the search
	is terminated.

	### Parameters
	nc_pid

	src_station_pid

	itinerary - in the form of a map `%{vehicleID, src_station, dst_station, dept_time, arrival_time, 
	mode_of_transport}`

	dst_schedule - in the form of a list of maps `%{vehicleID, src_station, dst_station, dept_time,
	arrival_time, mode_of_transport}`

	### Return values
	Returns {:ok}.
	"""
	def function(nc, src, itinerary, dest_schedule) do
		# schedule to reach this destination station is added to itinerary
		new_itinerary=List.flatten([itinerary|[dest_schedule]])
		[query]=Enum.take(new_itinerary, 1)
		{:ok, {_, dst}}=StationConstructor.lookup_code(nc, dest_schedule.dst_station)
		# new_itinerary is either returned to NC or sent on to next station to
		# continue additions
		if dest_schedule.dst_station==query.dst_station do
			query=query|>Map.delete(:day)
			if API.member(query) do
				query|>API.get|>elem(1)|>QC.collect(new_itinerary)
			end
		else
			Station.send_to_stn(nc, src, dst, new_itinerary)
		end
	end

	# Server-side callback functions

	def handle_event(:cast, {:update, old_vars}, _, _) do
		# new_vars is assigned values passed to argument old_vars, ie, new values to
		# update local variables with
		schedule=Enum.sort(old_vars.schedule, &(&1.dept_time<=&2.dept_time))
		new_vars=%StationStruct{loc_vars: old_vars.loc_vars, schedule: schedule,
			other_means: old_vars.other_means, station_number: old_vars.station_number,
			station_name: old_vars.station_name, pid: old_vars.pid, congestion_low:
			old_vars.congestion_low, congestion_high:	old_vars.congestion_high,
			choose_fn: old_vars.choose_fn}
		# depending on the state of the station, appropriate FSM state change is
		# made and new values are stored for the station
		case(new_vars.loc_vars.disturbance) do
			"yes"->
				{:next_state, :disturbance, new_vars}
			"no"->
				case(new_vars.loc_vars.congestion) do
					"none"->
						{:next_state, :delay, new_vars}
					"low"->
						# congestion_delay is computed using computation function
						# selected based on the choose_fn value
						congestion_delay=StationFunctions.func(new_vars.choose_fn).
						(new_vars.loc_vars.delay, new_vars.congestion_low)
						{_, update_loc_vars}=Map.get_and_update(new_vars.loc_vars,
							:congestion_delay, fn delay->{delay, congestion_delay} end)
						update_vars=%{new_vars|loc_vars: update_loc_vars}
						{:next_state, :delay, update_vars}
					"high"->
						# congestion_delay is computed using computation function
						# selected based on the choose_fn value
						congestion_delay=StationFunctions.func(new_vars.choose_fn).
						(new_vars.loc_vars.delay, new_vars.congestion_high)
						{_, update_loc_vars}=Map.get_and_update(new_vars.loc_vars,
							:congestion_delay, fn delay->{delay, congestion_delay} end)
						update_vars=%{new_vars|loc_vars: update_loc_vars}
						{:next_state, :delay, update_vars}
					_->
						{:next_state, :delay, new_vars}
				end
			_->
				{:next_state, :delay, new_vars}
		end
	end

	def handle_event({:call, from}, :get_vars, state, vars) do
		# station variables values are returned
		{:next_state, state, vars, [{:reply, from, vars}]}
	end

	def handle_event({:call, from}, :get_state, state, vars) do
		# station FSM state is returned
		{:next_state, state, vars, [{:reply, from, state}]}
	end

	def handle_event(:cast, {:receive_at_src, nc, src, itinerary}, state, vars) do
		[query]=Enum.take(itinerary, 1)
		neighbour_list=Station.check_neighbours(vars.schedule, vars.other_means,
			query.arrival_time, itinerary)
		# for each neighbouring station, function is called to determine new
		# itinerary additions
		Enum.each(neighbour_list, fn(x)->function(nc, src, itinerary, x) end)
		{:next_state, state, vars}
	end

	def handle_event(:cast, {:receive_at_stn, nc, src, itinerary}, state, vars) do
		[query]=Enum.take(itinerary, 1)
		[prev_stn]=Enum.take(itinerary, -1)
		# check for overnight trip
		{itinerary, query}=if prev_stn.arrival_time>86_400 do
			itinerary=List.delete(itinerary, query)
			query=Map.update!(query, :day, &(&1+1))
			itinerary=List.insert_at(itinerary, 0, query)
			{itinerary, query}
		else
			{itinerary, query}
		end
		# check if query active
		_=if StationConstructor.check_active(nc, Map.delete(query, :day))===true do
			neighbour_list=Station.check_neighbours(vars.schedule, vars.other_means,
				prev_stn.arrival_time, itinerary)
			# for each neighbouring station, function is called to determine new
			# itinerary additions
			Enum.each(neighbour_list, fn(x)->function(nc, src, itinerary, x) end)
			true
		else
			false
		end
		{:next_state, state, vars}
	end

	def handle_event(event_type, event_content, state, vars) do
		super(event_type, event_content, state, vars)
	end

end
