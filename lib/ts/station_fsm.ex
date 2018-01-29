defmodule StationFsm do
	@moduledoc """
	Provides implementation of the core logic of a Station.
	"""

	use Fsm, initial_state: :start, initial_data: []

	# Function definitions

	def process_itinerary(station_fsm, itinerary)  do
		station_fsm = station_fsm |>
		StationFsm.query_input(itinerary) |>
		StationFsm.check_query_status

		station_fsm = if StationFsm.state(station_fsm) != :ready do
			StationFsm.initialize(station_fsm)
		else
			station_fsm
		end

		if StationFsm.state(station_fsm) != :ready do
			StationFsm.process_station_schedule(station_fsm)
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


	def process_station_schedule(station_fsm) do
		station_fsm = StationFsm.check_stop(station_fsm)
		if StationFsm.state(station_fsm) != :ready do
			process_station_schedule(station_fsm)
		else
			station_fsm
		end
	end

	def exclude_previous_station(itinerary) do
		if length(itinerary) > 1 do
			[_| tail] = Enum.reverse(itinerary)
			Enum.reverse(tail)
		else
			[]
		end
	end

	# Check if the query is valid / completed / invalid

	def query_status(station_vars, registry, itinerary) do
		self = station_vars.station_number
		[last] = Enum.take(itinerary, -1)
		[query] = Enum.take(itinerary, 1)

		# Checking for validity
		# Check for timeout, loops and receiving of a wrong query
		# i.e. having a different dst_station than the current station

		except_last = exclude_previous_station(itinerary)

		# returns true if query is active, false otherwise
		active = registry.check_active(query.qid)

		cond do
			(active && length(itinerary) == 1) ->
				:valid
			(active && query.dst_station == last.dst_station) ->
				:collect
			(!active || check_member(self, except_last) || last.dst_station != self)
			->	:invalid
			true ->
				:valid
		end
	end

	# Initialise neighbours_fulfilment array

	def init_neighbours(schedule, _other_means) do

		# Find all possible neighbors of station
		# Append them to a list with value of each neighbour = 0

		# Add all elements of schedule to dst_schedule
		dst_sched = for x <- schedule do
			x.dst_station
		end

		# Add all elements of other_means to dst_om
		# dst_om = for x <- other_means do
		# 	x.dst_station
		# end

		# Create a concatenated list
		# dst = dst_sched ++ dst_om

		dst = dst_sched

		# Add neighbours from concatenated list
		Map.new(dst, fn x -> {x, 0} end)
	end

	def stop_fn(neighbours, schedule) do

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

	def feasibility_check(conn, itinerary, arrival_time, _sch_om) do
		[query | _] = itinerary
		# If connection is in schedule
		if conn.dept_time > arrival_time && (query.day * 86_400 + conn.arrival_time)
		 <=	query.end_time do
			:true
		else
			:false
		end
	end

	def update_days_travelled(itinerary) do
		[query | _] = itinerary

		if length(itinerary) > 1 do
			[previous_station] = 	Enum.take(itinerary, -1)

			if previous_station.arrival_time >= 86_400 do
				days = div(previous_station.arrival_time, 86_400)
				itinerary = List.delete_at(itinerary, 0)
				query = Map.update!(query, :day, &(&1 + days))
				itinerary = List.insert_at(itinerary, 0, query)
				{itinerary, Integer.mod(previous_station.arrival_time, 86_400)}
			else
				{itinerary, previous_station.arrival_time}
			end
		else
			{itinerary, query.arrival_time}
		end
	end

	# Check if there exists a potential loop for the next
	# station given the schedule of the current station

	def check_member(dst, itinerary) do
		#IO.inspect itinerary
		[head | tail] = itinerary
		dest_list = Enum.map(tail, fn (x) -> x[:dst_station] end)
		dest_list = [head.src_station | dest_list]
		Enum.member?(dest_list, dst)
	end

	# Check if preferences match

	def pref_check(_conn, _itinerary) do
		# Invoke UQCFSM and check for preferences
		:true
	end

	# Send the new itinerary to the neighbour

	def send_to_neighbour(conn, itinerary, registry) do
		# send itinerary to
		next_station_pid = registry.lookup_code(conn[:dst_station])
		# Forward itinerary to next station's pid
		GenServer.cast(next_station_pid, {:receive, itinerary})
	end

	def iterate_over_schedule([], itinerary, _sch_om,
		[{_neighbour_map, _schedule, arrival_time} ,
		station_vars, registry, qc, itinerary]) do

		next_state(:query_fulfilment_check, [{%{}, [], arrival_time} , station_vars,
		 registry, qc, itinerary])
	end

	# Iterate over the schedule and operate over each query

	def iterate_over_schedule([conn | schedule_tail], itinerary, sch_om,
		[{neighbour_map, _schedule, arrival_time} ,
		 station_vars, registry, qc, itinerary]) do

		# If query is feasible and preferable
		if feasibility_check(conn, itinerary, arrival_time, sch_om) &&
		pref_check(conn, itinerary) do
			# Append connection to itinerary
			itinerary = itinerary ++ [conn]
			# Send itinerary to neighbour
			send_to_neighbour(conn, itinerary, registry)
			# Update neighbour map
			neighbour_map = %{neighbour_map | conn[:dst_station] => 1}
			# Go to previous state and repeat
			next_state(:query_fulfilment_check, [{neighbour_map, schedule_tail,
			 arrival_time},	station_vars, registry, qc, itinerary])
		else
			# Pass over connection
			iterate_over_schedule(schedule_tail, itinerary, sch_om,
				[{neighbour_map, schedule_tail, arrival_time} ,
				 station_vars, registry, qc, itinerary])
		end

	end

	# State definitions

	# start state
	defstate start do
		# On getting the data input, go to ready state
		defevent input_data(station_vars, registry, qc) do
			vars = [station_vars, registry, qc]
			next_state(:ready, vars)
		end
	end

	# ready state
	defstate ready do
		# When local variables of the station are updated
		defevent update(new_vars), data: original_vars do
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
			vars = [new_station_vars, Enum.at(original_vars, 1),
			Enum.at(original_vars, 2)]
			next_state(:ready, vars)
		end

		# When an itinerary is passed to the station
		defevent query_input(itinerary), data: vars do
			vars =
			if length(vars) == 4 do
				List.delete_at(vars, 3)
			else
				vars
			end

			# Give itinerary as part of query
			vars = vars ++ [itinerary]
			next_state(:query_rcvd, vars)
		end
	end

	# query_rcvd state
	defstate query_rcvd do
		defevent check_query_status, data: vars = [station_vars, registry, qc,
		itinerary] do

			q_stat = query_status(station_vars, registry, itinerary)

			case q_stat do
				:invalid ->
					# If invalid query, remove itinerary
					vars = List.delete_at(vars, 3)
					vars = vars ++ [:invalid]
					next_state(:ready, vars)
				:collect ->
					# If completed query, send to
					qc.collect(itinerary)
					vars = List.delete_at(vars, 3)
					vars = vars ++ [:collect]
					next_state(:ready, vars)
				:valid ->
					# If valid query, compute further
					vars = vars ++ [:valid]
					next_state(:query_init, vars)
			end
		end
	end

	# query_init state
	defstate query_init do
		defevent initialize, data: _vars = [station_vars, registry, qc, itinerary,
		:valid] do

			# Find all neighbors
			neighbour_map = init_neighbours(station_vars.schedule,
			station_vars.other_means)
			# Replace neighbours keyword-list in struct
			# new_station_vars = %{station_vars | neighbours: nbrs}
			{itinerary, arrival_time} = update_days_travelled(itinerary)

			vars = [{neighbour_map, station_vars.schedule, arrival_time},
			station_vars, registry, qc, itinerary]

			next_state(:query_fulfilment_check, vars)
		end
	end

	# query_fulfilment_check state
	defstate query_fulfilment_check do
		defevent check_stop, data: vars = [{neighbour_map, schedule,
		_arrival_time} | vars_tail]  do
			should_stop = stop_fn(neighbour_map, schedule) # Find out if stop or not

			if should_stop == :true do
				next_state(:ready, vars_tail)
			else
				next_state(:compute_itinerary, vars)
			end

		end
	end

	# compute_itinerary state
	defstate compute_itinerary do
		defevent check_stop, data: vars = [{_neighbour_map, schedule,
		_arrival_time}, _station_vars, _registry, _qc, itinerary] do

			# Iterate over list schedule
			sch_om = :schedule
			iterate_over_schedule(schedule, itinerary, sch_om, vars)
		end
	end

end
