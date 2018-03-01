defmodule Util.Itinerary do
	@moduledoc """
	Defines the operations that can be performed on the itinerary container of the
	 format {query, route, preferences}.
	"""
	alias Util.Connection
	alias Util.Preference
	alias Util.Query
	# generates itinerary in the format {query, route, preference}
	def new(query, route, preference), do: {query, route, preference}

	def new(query, preference), do: {query, [], preference}

	def new(n) when n >= 0 do
		qid = Integer.to_string(:rand.uniform(10_000))
		src_station = :rand.uniform(1000)
		dst_station = :rand.uniform(1000)
		arrival_time = :rand.uniform(1000)
		end_time = :rand.uniform(1000)
		query = %Query{
			qid: qid,
			src_station: src_station,
			dst_station: dst_station,
			arrival_time: arrival_time,
			end_time: end_time
		}

		mode_of_transport = Integer.to_string(:rand.uniform(10_000))
		day = :rand.uniform(10)
		preference = %Preference{ day: day, mode_of_transport: mode_of_transport}
		route = loop(n, [])
		{query, route, preference}
	end

	def loop(n, acc) when n > 0 do
		vid = Integer.to_string(:rand.uniform(10_000))
		src_station = :rand.uniform(10_000)
		mode_of_transport = Integer.to_string(:rand.uniform(10_000))
		dst_station = :rand.uniform(10)
		dept_time = :rand.uniform(10)
		arrival_time = :rand.uniform(10)
		connection = %Connection{
			vehicleID: vid,
			src_station: src_station,
			mode_of_transport: mode_of_transport,
			dst_station: dst_station,
			dept_time: dept_time,
			arrival_time: arrival_time}
			loop(n - 1, [connection | acc])
	end

	def loop(0, acc), do: acc

end




# itinerary = Itinerary.new(%Query{qid: "0300", src_station: 0,
# 	dst_station: 3, arrival_time: 0, end_time: 999_999},
# 	[%Connection{vehicleID: "99", src_station: 0, mode_of_transport: "train",
# 	dst_station: 1, dept_time: 10_000, arrival_time: 20_000}], %Preference{day: 0})
