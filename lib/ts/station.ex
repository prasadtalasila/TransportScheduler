defmodule Station do
	
	use Fsm, initial_state: :start, initial_data: []

	# Function definitions

	# Check if the query is valid / completed / invalid
	def query_status(registry, itinerary) do
		# check for self loops
		# timeout check
		# check other parameters (dst_station)
		:valid
	end

	# Send the itinerary to the qc if completed
	def send_to_qc(qc, itinerary) do
		# send itinerary to qc
	end

	# Initialise neighbours_fulfilment array
	def init_neighbors() do
		# Find all possible neighbors of station
		# Append them to a list with value of each neighbour = 0
		[]
	end

	def replace_neighbors(neighbors, vars) do
		[]
	end

	# Check if all connections have been used
	def stop_fn(neighbours) do
		# If value of every key in neighbours is 1, return :true
		# Else return false
		:false
	end

	# Check if connection is feasible
	def feasibility_check(conn) do
		:true
	end

	# Check if preferences match
	def pref_check(conn) do
		# Invoke UQCFSM and check for preferences
		:true
	end

	def send_to_neighbour(head, itinerary) do
		#
	end 
	
	# conn - map -> %{vehicleID: "100", src_station: 1, mode_of_transport: "bus",
	#		dst_station: 2, dept_time: 25000, arrival_time: 35000}
	def update_query(conn, itinerary) do
		[]
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
			# Give itinerary as part of queryit 
			vars = vars.append(itinerary)
			next_state(:query_rcvd, vars)
		end
	end

	# query_rcvd state
	defstate query_rcvd do
		defevent check_query_status, data: vars = [_, registry, qc, itinerary] do
			# Check status of query
			q_stat = query_status(registry, itinerary)

			case q_stat do
				:invalid ->
					# If invalid query, remove itinerary
					vars = List.delete_at(vars, 3)
					next_state(:ready, vars)
				:collect ->
					# If completed query, send to qc
					send_to_qc(qc, itinerary)
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
		defevent initialize, data: vars do
			neighbors = init_neighbors() # Find all neighbors
			# DO HERE
			vars = replace_neighbors(neighbors, vars) # Replace neighbors in vars
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
			for conn <- om do
				if (feasibility_check(conn) == :true && pref_check(conn) == :true) do
					itinerary = update_query(conn, itinerary)
					send_to_neighbour(conn, itinerary)
					next_state(:query_fulfilment_check)
				end
			end

			sched = station_vars.schedule
			# Iterate over list schedule
			for conn <- sched do
				if (feasibility_check(conn) == :true && pref_check(conn) == :true) do
					itinerary = update_query(conn, itinerary)
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