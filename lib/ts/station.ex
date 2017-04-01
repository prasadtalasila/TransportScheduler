# Module to create a station process and FSM and handle local variable updates

defmodule Station do
	use GenStateMachine, async: true

	def start_link do
		GenStateMachine.start_link(Station, {:nodata, nil})
	end

	# Client-side getter and setter functions

	def update(station,  %StationStruct{}=new_vars) do
		GenStateMachine.cast(station, {:update, new_vars})
	end

	def get_vars(station) do
		GenStateMachine.call(station, :get_vars)
	end
	
	def get_state(station) do
		GenStateMachine.call(station, :get_state)
	end

	# Client-side message-passing functions
	
	def receive_at_src(nc, src, itinerary) do
		GenStateMachine.cast(src, {:receive_at_src, nc, src, itinerary})
	end

	def send_to_stn(nc, src, dst, itinerary) do
		GenStateMachine.cast(dst, {:receive_at_stn, nc, src, itinerary})
	end

	#def send_to_NC(server, itinerary) do
		#StationConstructor.receive_from_dest(server, itinerary)
	#end

	def dst_not_in_it(dst, it) do
		[_|it2]=it
		dst_list=Enum.map(it2, fn (x)->x[:dst_station] end)
		!Enum.member?(dst_list, dst)
	end
	
	def check_neighbours(schedule, other_means, time, itinerary) do
		# schedule is filtered to reject neighbours with departure time earlier
		# than arrival time at the station for the current itinerary
		time=if time>86_400 do
			time-86_400
		else
			time
		end
		next_list=Enum.filter(schedule, fn(x)->x.dept_time>time and
			dst_not_in_it(x.dst_station, itinerary) end)
		possible_walks=Enum.filter(other_means, 
			fn(x)->dst_not_in_it(x.dst_station, itinerary) end)
		list=for x<-possible_walks do
			%{vehicleID: "OM", src_station: x.src_station, dst_station:
			x.dst_station, dept_time: time, arrival_time: time+x.travel_time,
			mode_of_transport: "Other Means"}
		end
		List.flatten(list, next_list)
	end

	def function(nc, src, itinerary, dstSched) do
		# schedule to reach this destination station is added to itinerary
		newItinerary=List.flatten([itinerary|[dstSched]])
		[query]=Enum.take(newItinerary, 1)
		{:ok, {_, dst}}=StationConstructor.lookup_code(nc, dstSched.dst_station)
		# newItinerary is either returned to NC or sent on to next station to
		# continue additions
		if dstSched.dst_station==query.dst_station do
			#if (dstSched.arrival_time>86400) do
			#  newItinerary=List.delete(newItinerary, query)
			#  query=Map.update!(query, :day, &(&1-1))
			#  newItinerary=List.insert_at(newItinerary, 0, query)
			#end
			#IO.inspect query
			#Station.send_to_NC(nc, newItinerary)
			query=query|>Map.delete(:day)
			if API.member(query) do
				#query|>API.get|>elem(2)|>send({:add_itinerary, newItinerary})
				query|>API.get|>elem(1)|>QC.collect(newItinerary)
			end
		else
			Station.send_to_stn(nc, src, dst, newItinerary)
		end
	end

	# Server-side callback functions
	
	def handle_event(:cast, {:update, old_vars}, _, _) do
		# new_vars is assigned values passed to argument old_vars, ie, new values to
		# update local variables with
		schedule=Enum.sort(old_vars.schedule, &(&1.dept_time<=&2.dept_time))
		new_vars=%StationStruct{loc_vars: old_vars.loc_vars, schedule: schedule,
		other_means: old_vars.other_means, station_number: old_vars.station_number,
		station_name: old_vars.station_name, pid: old_vars.pid,
						congestion_low: old_vars.congestion_low, congestion_high:
						old_vars.congestion_high, choose_fn: old_vars.choose_fn}
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
		#IO.inspect query
		next_list=Station.check_neighbours(vars.schedule, vars.other_means,
			query.arrival_time, itinerary)
		# for each neighbouring station, function is called to determine new
		# itinerary additions
		Enum.each(next_list, fn(x)->function(nc, src, itinerary, x) end)
		{:next_state, state, vars}
	end

	def handle_event(:cast, {:receive_at_stn, nc, src, itinerary}, state, vars) do
		[query]=Enum.take(itinerary, 1)
		[prev_stn]=Enum.take(itinerary, -1)
		#IO.inspect query
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
			next_list=Station.check_neighbours(vars.schedule, vars.other_means,
				prev_stn.arrival_time, itinerary)
			# for each neighbouring station, function is called to determine new
			# itinerary additions
			Enum.each(next_list, fn(x)->function(nc, src, itinerary, x) end)
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
