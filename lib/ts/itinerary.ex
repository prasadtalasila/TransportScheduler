defmodule Itinerary do
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
end
