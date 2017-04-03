defmodule Mix.Tasks.TSProfile do
	@moduledoc """
	Code profiling code
	"""
	use Mix.Task
  import ExProf.Macro

	@doc "analyze with profile macro"
	def do_analyze do
		{_, _}=API.start_link
			{:ok, pid}=InputParser.start_link
			stn_map=InputParser.get_station_map(pid)
			for stn_key<-Map.keys(stn_map) do
				stn_code=Map.get(stn_map, stn_key)
				stn_struct=InputParser.get_station_struct(pid, stn_key)
				#IO.inspect stn_struct
				StationConstructor.create(StationConstructor, stn_key, stn_code)
				{:ok, {_, station}}=StationConstructor.lookup_name(StationConstructor,
					stn_key)
				Station.update(station, stn_struct)
			end
		 query=%{src_station: 1, dst_station: 324, arrival_time: 13_200}
				#registry=API.get(:NC)
				{:ok, {_, stn}}=StationConstructor.lookup_code(StationConstructor, 1)
				API.put("conn", query, [])
				StationConstructor.add_query(StationConstructor, query, "conn")
				#:timer.sleep(50)
				itinerary=[Map.put(query, :day, 0)]
			profile do
				StationConstructor.send_to_src(StationConstructor, stn, itinerary)
				#IO.inspect self()
				#IO.inspect query
				API.put(query, self())
				Process.send_after(self(), :timeout, 10_000)
				receive do
					:timeout->
						StationConstructor.del_query(StationConstructor, query)
						#conn|>put_status(200)|>json(API.get(conn)|>sort_list)
						API.remove("conn")
						API.remove(query)
					:release->
						#conn|>put_status(200)|>json(API.get(conn)|>sort_list)
						API.remove("conn")
						API.remove(query)
				end
			end
	end

	@doc "get analysis records and sum them up"
	def run do
		records=do_analyze
		total_percent=Enum.reduce(records, 0.0, &(&1.percent+&2))
		IO.inspect "total = #{total_percent}"
	end
end
