defmodule StationFsm do

	use Fsm, initial_state: :start, initial_data: []
	use GenServer

	# Function definitions

	# Check if the query is valid / completed / invalid
	def query_status(station_vars, registry, itinerary) do
		[query] = Enum.take(itinerary, 1)
		[last] = Enum.take(itinerary, -1)
		self = station_vars.station_number

		# Checking for validity
		# Check for timeout, loops and receiving of a wrong query
		# i.e. having a different dst_station than the current station
		except_last = itinerary
		if length(itinerary) > 1 do
			[_| tail] = Enum.reverse(itinerary)
			except_last = Enum.reverse(tail)
		end


		# This would return a list having 3 elements,
		# [qid, active, qc_pid] and active would indicate if query
		# is currently active or not
		# timeout = :collect or :timeout
		query_stat = registry.check_active(query.qid)

		qs = :valid

		if query_stat == true || check_dest(self, except_last) || last.dst_station != self do
			qs = :invalid
		end

		if query.dst_station == last.dst_station do
			qs = :collect
		end

		if length(itinerary) == 1 do
			qs = :valid
		end

		qs

	end

	# Initialise neighbours_fulfilment array
	def init_neighbours(schedule, other_means) do
		# Find all possible neighbors of station
		# Append them to a list with value of each neighbour = 0
		nbrs = %{}

		# Add neighbours from schedule
		for x <- schedule do
			Map.put(nbrs, x.dst_station, 0)
		end

		# Add neighbours in other_means
		for x <- other_means do
			Map.put(nbrs, x.dst_station, 0)
		end

		nbrs
	end

	# Check if all connections have been used
	def stop_fn(neighbours) do
		# If value of every key in neighbours is 1, return :true
		# Else return false
		for {_, v} <- neighbours do
			if v == 0 do
				:false
			end
		end

		:true
	end

	# Check if connection is feasible
	def feasibility_check(conn, itinerary, sch_om) do
		[query] = Enum.take(itinerary, 1)
		time = query.arrival_time

		# Time adjustment
		time = if time > 86_400 do
			time - 86_400
		else
			time
		end

		# If connection is in schedule
		if sch_om == :schedule do
			if conn.dept_time > time && check_dest(conn.dst_station, itinerary) &&
			(query.day * 86_400 + conn.arrival_time <= query.end_time) do
				:true
			end
		end

		# If connection is in other_means
		if sch_om == :other_means do
			if check_dest(conn.dst_station, itinerary) do
				:true
			end
		end

		:false
	end

	# Check if there exists a potential loop for the next
	# station given the schedule of the current station
	def check_dest(dst, itinerary) do
		[_| tail] = itinerary
		dest_list = Enum.map(tail, fn (x) -> x[:dst_station] end)
		!Enum.member?(dest_list, dst)
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
		# next_station.query_input(itinerary)
		# GenServer.cast(next_station_pid, itinerary)
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
			schedule = Enum.sort(new_vars.schedule, &(&1.dept_time<=&2.dept_time))
			new_station_vars = %StationStruct{loc_vars: new_vars.loc_vars, schedule: schedule,
				other_means: new_vars.other_means, station_number: new_vars.station_number,
				station_name: new_vars.station_name, pid: new_vars.pid, congestion_low:
				new_vars.congestion_low, congestion_high:	new_vars.congestion_high,
				choose_fn: new_vars.choose_fn}

			# Return to ready state with new variables
			vars = [new_station_vars, Enum.at(original_vars, 1), Enum.at(original_vars, 2)]
			next_state(:update, vars)
		end

		# When an itinerary is passed to the station
		defevent query_input(itinerary), data: vars do
			# Give itinerary as part of query
			vars = vars ++ [itinerary]
			next_state(:query_rcvd, vars)
		end
	end

	# query_rcvd state
	defstate query_rcvd do
		defevent check_query_status, data: vars = [station_vars, registry, qc, itinerary] do
			# Check status of query
			q_stat = query_status(station_vars, registry, itinerary)

			case q_stat do
				:invalid ->
					# If invalid query, remove itinerary
					vars = List.delete_at(vars, 3)
					next_state(:ready, vars)
				:collect ->
					# If completed query, send to qc
					qc.collect(itinerary)
					vars = List.delete_at(vars, 3)
					next_state(:ready, vars)
				:valid ->
					# If valid query, compute further
					next_state(:query_init)
			end
		end
	end

	# query_init state
	defstate query_init do
		defevent initialize, data: [station_vars, registry, qc, itinerary] do
			# Find all neighbors
			neighbour_map = init_neighbours(station_vars.schedule, station_vars.other_means)
			# Replace neighbours keyword-list in struct
			# new_station_vars = %{station_vars | neighbours: nbrs}
			vars = [{neighbour_map, station_vars.schedule}, station_vars, registry, qc, itinerary]
			next_state(:query_fulfilment_check, vars)
		end
	end

	# query_fulfilment_check state
	defstate query_fulfilment_check do
		defevent check_stop, data: vars = [{neighbour_map, schedule} | vars_tail] do
			should_stop = stop_fn(neighbour_map) # Find out if stop or not
			if should_stop == :true do
				next_state(:ready, vars_tail)
			else
				next_state(:compute_itinerary, vars)
			end

		end
	end

	# compute_itinerary state
	defstate compute_itinerary do
		defevent compute_connections, data: vars = [{neighbour_map, schedule} ,station_vars, registry, qc, itinerary] do
			om = station_vars.other_means

			# Iterate over list schedule
			sch_om = :schedule
			iterate_over_schedule(schedule, itinerary, sch_om, vars)

		end
	end

	def iterate_over_schedule([], itinerary, sch_om, vars = [{neighbour_map, schedule} ,station_vars, registry, qc, itinerary]) do

			next_state(:query_fulfilment_check, [{%{}, []} ,station_vars, registry, qc, itinerary])
	end

	def iterate_over_schedule([conn | schedule_tail], itinerary, sch_om, vars = [{neighbour_map, schedule} ,station_vars, registry, qc, itinerary]) do
		if (feasibility_check(conn, itinerary, sch_om) == :true &&
			pref_check(conn, itinerary) == :true) do
			itinerary = itinerary ++ [conn]
			send_to_neighbour(conn, itinerary, registry)
			Map.put(neighbour_map, conn[:dst_station], 1)
			next_state(:query_fulfilment_check, [{neighbour_map, schedule_tail} ,station_vars, registry, qc, itinerary])

		else
			iterate_over_schedule(schedule_tail, itinerary, sch_om, [{neighbour_map, schedule_tail} ,station_vars, registry, qc, itinerary])
		end

	end

	# Global events

	# Stay in the same state and do nothing if undefined event
	defevent _ do
	end
end