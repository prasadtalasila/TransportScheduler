defmodule StationFsm do
	@moduledoc """
	Provides implementation of the core logic of a Station.
	"""

	use Fsm, initial_state: :start, initial_data: []
	require Itinerary

	# Function definitions
	def initialise_fsm(input = [_station_vars,
	{_registry, _qc, _station}]) do
		StationFsm.new |>
		StationFsm.input_data(input)
	end

	def process_itinerary(station_fsm, itinerary)  do
		station_fsm = station_fsm |>
		StationFsm.query_input(itinerary) |>
		StationFsm.check_query_status

		station_fsm = if StationFsm.state(station_fsm) != :ready do
			StationFsm.initialise(station_fsm)
		else
			station_fsm
		end

		if StationFsm.state(station_fsm) != :ready do
			process_station_schedule(station_fsm)
		else
			station_fsm
		end
	end

	def get_timetable(station_fsm) do
		station_state = station_fsm
		|> StationFsm.data
		|> Enum.at(0)

		station_state.schedule
	end

	defp process_station_schedule(station_fsm) do
		station_fsm = StationFsm.check_stop(station_fsm)
		if StationFsm.state(station_fsm) != :ready do
			process_station_schedule(station_fsm)
		else
			station_fsm
		end
	end

	# defp exclude_previous_station(itinerary) do
	# 	if length(itinerary) > 1 do
	# 		[_| tail] = Enum.reverse(itinerary)
	# 		Enum.reverse(tail)
	# 	else
	# 		[]
	# 	end
	# end

	# Check if the query is valid / completed / invalid

	defp query_status(station_vars, registry, itinerary) do
		# returns true if query is active, false otherwise
		active = registry.check_active(Itinerary.get_query_id(itinerary))

		cond do
			(active && Itinerary.is_empty(itinerary)) ->
				:valid
			(active && Itinerary.is_terminal(itinerary)) ->
				:collect
			(!active ||
			!Itinerary.is_valid_destination(station_vars.station_number, itinerary))
			->	:invalid
			true ->
				:valid
		end
	end

	# Initialise neighbours_fulfilment array
	defp init_neighbours(schedule, _other_means) do
		dst = schedule

		# Add neighbours from concatenated list
		Map.new(dst, fn x -> {x.dst_station, 0} end)
	end

	defp stop_fn(neighbours, schedule) do

		check_unvisited_neighbour = fn ({_, val}, acc) ->
			if val == 0 do
				:true
			else
				acc
			end
		end

		if schedule != [] &&
		Enum.reduce(neighbours, :false, check_unvisited_neighbour) == :true do
			:false
		else
			:true
		end
	end

	# Check if connection is feasible

	defp feasibility_check(conn, itinerary, arrival_time, _sch_om) do
		query = Itinerary.get_query(itinerary)
		preference = Itinerary.get_preference(itinerary)
		# If connection is in schedule
		if conn.dept_time > arrival_time &&
		(preference.day * 86_400 + conn.arrival_time) <=	query.end_time do
			:true
		else
			:false
		end
	end

	defp update_days_travelled(itinerary) do
		query = Itinerary.get_query(itinerary)

		if Itinerary.is_empty(itinerary) do
			{itinerary, query.arrival_time}
		else
			previous_link = Itinerary.get_last_link(itinerary)

			if previous_link.arrival_time >= 86_400 do
				day_increment = div(previous_link.arrival_time, 86_400)
				new_itinerary = Itinerary.increment_day(itinerary, day_increment)
				{new_itinerary, Integer.mod(previous_link.arrival_time, 86_400)}
			else
				{itinerary, previous_link.arrival_time}
			end
		end
	end

	# Check if there exists a potential loop for the next
	# station given the schedule of the current station

	# defp check_member(dst, itinerary) do
	# 	[head | tail] = itinerary
	# 	dest_list = Enum.map(tail, fn (x) -> x[:dst_station] end)
	# 	dest_list = [head.src_station | dest_list]
	# 	Enum.member?(dest_list, dst)
	# end

	# Check if preferences match

	defp pref_check(_conn, _itinerary) do
		# Invoke UQCFSM and check for preferences
		:true
	end

	# Send the new itinerary to the neighbour

	defp send_to_neighbour(conn, itinerary, registry, station) do
		# send itinerary to
		next_station_pid = registry.lookup_code(conn[:dst_station])
		# Forward itinerary to next station's pid
		station.send_query(next_station_pid, itinerary)
	end

	defp iterate_over_schedule(_sch_om, [{_neighbour_map, [], arrival_time} ,
		itinerary, station_vars, {registry, qc, station}]) do

		#Pass empty neighbour map which will give true for stop_fn
		next_state(:query_fulfilment_check, [{%{}, [], arrival_time} , itinerary,
		station_vars, {registry, qc, station}])
	end

	# Iterate over the schedule and operate over each query

	defp iterate_over_schedule(sch_om, [{neighbour_map,
	[conn | schedule_tail], arrival_time} , itinerary, station_vars,
	{registry, qc, station}]) do
		# If query is feasible and preferable
		if feasibility_check(conn, itinerary, arrival_time, sch_om) &&
		pref_check(conn, itinerary) && neighbour_map[conn.dst_station] == 0 &&
		!Itinerary.check_member(itinerary, conn) do
			# Append connection to itinerary
			new_itinerary = Itinerary.add_link(itinerary, conn)
			# Send itinerary to neighbour
			send_to_neighbour(conn, new_itinerary, registry, station)
			# Update neighbour map
			new_neighbour_map = %{neighbour_map | conn[:dst_station] => 1}
			# Go to previous state and repeat
			next_state(:query_fulfilment_check, [{new_neighbour_map, schedule_tail,
			 arrival_time},	itinerary, station_vars, {registry, qc, station}])
		else
			# Pass over connection
			iterate_over_schedule(sch_om, [{neighbour_map, schedule_tail,
			arrival_time}, itinerary, station_vars, {registry, qc, station}])
		end

	end

	# State definitions

	# start state
	defstate start do
		# On getting the data input, go to ready state
		defevent input_data(station_data = [_station_vars,
		{_registry, _qc, _station}])
		do
			next_state(:ready, station_data)
		end
	end

	# ready state
	defstate ready do
		# When local variables of the station are updated
		defevent update(new_vars), data: [_station_vars,
		dependencies = {_registry, _qc, _station}]do
			# Replace each entry in the struct original_vars with each entry
			# in new_vars

			schedule = Enum.sort(new_vars.schedule, &(&1.dept_time <= &2.dept_time))
			new_station_vars = %StationStruct{loc_vars: new_vars.loc_vars,
			 schedule: schedule,
			 other_means: new_vars.other_means,
			 station_number: new_vars.station_number,
			 station_name: new_vars.station_name,
			 pid: new_vars.pid,
			 congestion_low: new_vars.congestion_low,
			 congestion_high:	new_vars.congestion_high,
			 choose_fn: new_vars.choose_fn}

			# Return to ready state with new variables
			vars = [new_station_vars, dependencies]
			next_state(:ready, vars)
		end

		# When an itinerary is passed to the station
		defevent query_input(itinerary), data: vars = [_station_vars,
		{_registry, _qc, _station}] do

			# Give itinerary as part of query
			vars = [itinerary | vars]
			next_state(:query_rcvd, vars)
		end
	end

	# query_rcvd state
	defstate query_rcvd do
		defevent check_query_status, data: vars = [itinerary, station_vars,
		 {registry, qc, _station}] do

			q_stat = query_status(station_vars, registry, itinerary)

			case q_stat do
				:invalid ->
					# If invalid query, remove itinerary
					new_vars = List.delete_at(vars, 0)
					next_state(:ready, new_vars)
				:collect ->
					# If completed query, send to
					qc.collect(itinerary)
					new_vars = List.delete_at(vars, 0)
					next_state(:ready, new_vars)
				:valid ->
					# If valid query, compute
					next_state(:query_init, vars)
			end
		end
	end

	# query_init state
	defstate query_init do
		defevent initialise, data: vars = [itinerary, station_vars, _dependencies]
		 do

			# Find all neighbors
			neighbour_map = init_neighbours(station_vars.schedule,
			station_vars.other_means)

			# Replace neighbours keyword-list in struct
			# new_station_vars = %{station_vars | neighbours: nbrs}
			{itinerary, arrival_time} = update_days_travelled(itinerary)

			vars = [itinerary | List.delete_at(vars, 0)]
			new_vars = [{neighbour_map, station_vars.schedule, arrival_time} | vars]

			next_state(:query_fulfilment_check, new_vars)
		end
	end

	# query_fulfilment_check state
	defstate query_fulfilment_check do
		defevent check_stop, data: vars = [{neighbour_map, schedule,
		_arrival_time} | vars_tail]  do
			should_stop = stop_fn(neighbour_map, schedule) # Find out if stop or not

			if should_stop == :true do
				new_vars = List.delete_at(vars_tail, 0)
				next_state(:ready, new_vars)
			else
				next_state(:compute_itinerary, vars)
			end

		end
	end

	# compute_itinerary state
	defstate compute_itinerary do
		defevent check_stop, data: vars do

			# Iterate over list schedule
			sch_om = :schedule
			iterate_over_schedule(sch_om, vars)
		end
	end

end
