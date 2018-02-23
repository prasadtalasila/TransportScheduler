defmodule Util.Itinerary do
	@moduledoc """
	Defines the operations that can be performed on the itinerary container of the
	 format {query, route, preferences}.
	"""

	# generates itinerary in the format {query, route, preference}
	def new(query, route, preference), do: {query, route, preference}

	def new(query, preference), do: {query, [], preference}

	# Returns query contained in the itinerary.
	def get_query(itinerary), do: elem(itinerary, 0)

	# Returns the query id of the itinerary.
	def get_query_id(itinerary), do: get_query(itinerary).qid

	# Returns the partial/complete route.
	def get_route(itinerary), do: elem(itinerary, 1)

	# Returns the preferences for the itinerary.
	def get_preference(itinerary), do: elem(itinerary, 2)

	# Increments the the days travelled in the itinerary.
	def increment_day({query, route, preference}, value) do
		new_preference = Map.update!(preference, :day, &(&1 + value))
		{query, route, new_preference}
	end

	# Returns the route wihout the last link in the route.
	def exclude_last_link(itinerary) do
		[_ | tail] = elem(itinerary, 1)
		tail
	end

	# Returns the last link in the itinerary route.
	def get_last_link(itinerary) do
		[head | _] = elem(itinerary, 1)
		head
	end

	# Returns true if the itinerary route is empty.
	def is_empty(itinerary) do
		route = get_route(itinerary)
		if route == [] do
			true
		else
			false
		end
	end

	# Returns true if the itinerary is terminal.
	def is_terminal(itinerary) do
		query = get_query(itinerary)
		last_link = get_last_link(itinerary)
		query.dst_station == last_link.dst_station
	end

	# Returns true if the route stops (This does not mean it has reached the final
	# destination) at the the given station argument
	def is_valid_destination(present_station, itinerary) do
		present_station == get_last_link(itinerary).dst_station
	end

	# Adds a link to the present itinerary route.
	def add_link({query, route, preference}, link) do
		new_route = [link | route]
		{query, new_route, preference}
	end

	# Checks if adding link will generate a selfloop.
	def check_member({_query, route, _preference}, link), do: match_station(route, link)

	defp match_station([], _link), do: false
	defp match_station([head | tail], link) do
		if head.src_station == link.dst_station do
			true
		else
			match_station(tail, link)
		end
	end

	# Returns true if iteration over the schedule to compute new itineraries
	# has been completed with the set constraints
	defp stop_fn(neighbours, schedule) do

		check_unvisited_neighbour = fn ({_, val}, acc) ->
			if val == 0 do
				true
			else
				acc
			end
		end

		if schedule != [] &&
		Enum.reduce(neighbours, false, check_unvisited_neighbour) == true do
			false
		else
			true
		end
	end

	# Check if preferences match
	def pref_check(_conn, _itinerary) do
		# Invoke UQCFSM and check for preferences
		:true
	end

	# Send the new itinerary to the neighbour
	defp send_to_neighbour(conn, itinerary, dependency) do
		registry = dependency.registry
		station = dependency.station
		# send itinerary to
		next_station_pid = registry.lookup_code(conn.dst_station)
		# Forward itinerary to next station's pid
		station.send_query(next_station_pid, itinerary)
	end

	# Check if connection is feasible
	defp feasibility_check(conn, itinerary, arrival_time) do
		query = get_query(itinerary)
		preference = get_preference(itinerary)
		# If connection is in schedule
		if conn.dept_time > arrival_time &&
		(preference.day * 86_400 + conn.arrival_time) <=	query.end_time do
			:true
		else
			:false
		end
	end

	# Iterate over the schedule to find a valid connection.
	defp find_valid_connection([{_neighbour_map, [], arrival_time} ,
		itinerary, station_vars, dependency]) do

		#Pass empty neighbour map which will give true for stop_fn
		process_schedule([{%{}, [], arrival_time} , itinerary,
		station_vars, dependency])
	end

	defp find_valid_connection([{neighbour_map,
	[conn | schedule_tail], arrival_time} , itinerary, station_vars,
	dependency]) do
		# If query is feasible and preferable
		if feasibility_check(conn, itinerary, arrival_time) &&
		pref_check(conn, itinerary) && neighbour_map[conn.dst_station] == 0 &&
		!check_member(itinerary, conn) do
			# Append connection to itinerary
			new_itinerary = add_link(itinerary, conn)
			# Send itinerary to neighbour
			send_to_neighbour(conn, new_itinerary, dependency)
			# Update neighbour map
			new_neighbour_map = %{neighbour_map | conn.dst_station => 1}
			# Go to previous state and repeat
			process_schedule([{new_neighbour_map, schedule_tail,
			 arrival_time},	itinerary, station_vars, dependency])
		else
			# Pass over connection
			find_valid_connection([{neighbour_map, schedule_tail,
			arrival_time}, itinerary, station_vars, dependency])
		end

	end

	# Iterates over the the station schedule to generate new itineraries to be
	# sent to neighbouring stations.
	def process_schedule(vars = [{neighbour_map, schedule, _arrival_time} |
	vars_tail])  do

		should_stop = stop_fn(neighbour_map, schedule) # Find out if stop or not

		if should_stop == :true do
			List.delete_at(vars_tail, 0)
		else
			find_valid_connection(vars)
		end

	end
end
