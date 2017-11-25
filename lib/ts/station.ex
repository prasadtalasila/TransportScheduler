defmodule Station do
	
	use Fsm, initial_state: :start, initial_data: []

	############################################################################

	# Function definitions

	# Check if the query is valid / completed / invalid
	def query_status(station_vars, registry, itinerary) do
		[query] = Enum.take(itinerary, 1)
		[last] = Enum.take(itinerary, -1)
		self = station_vars.station_number

		# Checking for validity
		# Check for timeout, loops and receiving of a wrong query
		# i.e. having a different dst_station than the current station
		[_| tail] = Enum.reverse(itinerary)
		except_last = Enum.reverse(tail)
		
		# This would return a list having 3 elements,
		# [qid, active, qc_pid] and active would indicate if query
		# is currently active or not
		# timeout = :collect or :timeout
		query_stat = registry.get(query.qid)

		if Enum.at(query_stat, 1) == :timeout || check_dest(self, except_last) 
			|| last.dst_station != self do
			:invalid
		end

		if query.dst_station == last.dst_station do
			:collect
		end

		:valid
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
	def send_to_neighbour(_conn, _itinerary) do
		# send itinerary to neighbour
	end 

	###############################################################################

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
			vars = vars.append(itinerary)
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
			nbrs = init_neighbours(station_vars.schedule, station_vars.other_means)
			# Replace neighbours keyword-list in struct 
			new_station_vars = %{station_vars | neighbours: nbrs}
			vars = [new_station_vars, registry, qc, itinerary]
			next_state(:query_fulfilment_check, vars)
		end
	end

	# query_fulfilment_check state
	defstate query_fulfilment_check do
		defevent check_stop, data: vars = [station_vars, _, _, _] do
			should_stop = stop_fn(station_vars.neighbours) # Find out if stop or not
			if should_stop == :true do
				vars = List.delete_at(vars, 3)
				next_state(:ready, vars)
			else
				next_state(:compute_itinerary)
			end
		end
	end

	# compute_itinerary state
	defstate compute_itinerary do
		defevent compute_connections, data: [station_vars, _, _, itinerary] do
			om = station_vars.other_means
			# Iterate over list other_means
			sch_om = :other_means
			for conn <- om do
				if (feasibility_check(conn, itinerary, sch_om) == :true && 
					pref_check(conn, itinerary) == :true) do
					itinerary = itinerary ++ [conn]
					send_to_neighbour(conn, itinerary)
					next_state(:query_fulfilment_check)
				end
			end

			sched = station_vars.schedule
			# Iterate over list schedule
			sch_om = :schedule
			for conn <- sched do
				if (feasibility_check(conn, itinerary, sch_om) == :true && 
					pref_check(conn, itinerary) == :true) do
					itinerary = itinerary ++ [conn]
					send_to_neighbour(conn, itinerary)
					next_state(:query_fulfilment_check)
				end
			end
		end
	end

	# Global events

	# Stay in the same state and do nothing if undefined event
	defevent _ do

	end
end