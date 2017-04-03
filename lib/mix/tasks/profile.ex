defmodule Mix.Tasks.Profile do
	@moduledoc """
	Code profiling code
	"""
	use Mix.Task
	import ExProf.Macro

	@doc "analyze with profile macro"
	def do_analyze do
		TS.Supervisor.start_link
		{:ok, pid}=InputParser.start_link
		stn_map=InputParser.get_station_map(pid)
		stn_sched=InputParser.get_schedules(pid)
		for stn_key<-Map.keys(stn_map) do
			stn_code=Map.get(stn_map, stn_key)
			stn_struct=InputParser.get_station_struct(pid, stn_key)
			StationConstructor.create(StationConstructor, stn_key, stn_code)
			{:ok, {code, station}}=StationConstructor.lookup_name(StationConstructor,
				stn_key)
			Station.update(station, stn_struct)
		end
		{:ok, {code1, stn1}}=StationConstructor.lookup_name(StationConstructor,
			"Madgaon")
		{:ok, {code2, stn2}}=StationConstructor.lookup_name(StationConstructor,
			"Ratnagiri")
		itinerary=[%{src_station: code1, dst_station: code2, arrival_time: 0}]
		it1=List.first(itinerary)
		API.start_link
		API.put("conn", it1, [])
		StationConstructor.add_query(StationConstructor, it1, "conn")
		#:timer.sleep(50)
		itinerary=[Map.put(it1, :day, 0)]
		{:ok, pid}=QC.start_link
		API.put(it1, {self(), pid})
		profile do
			StationConstructor.send_to_src(StationConstructor, stn1, itinerary)
			Process.send_after(self(), :timeout, 500)
			receive do
			:timeout->
				StationConstructor.del_query(StationConstructor, it1)
				final=API.get("conn")
				API.remove("conn")
				API.remove(it1)
				QC.stop(pid)
			:release->
				final=API.get("conn")
				API.remove("conn")
				API.remove(it1)
				QC.stop(pid)
			end
		end
	end

	@doc "get analysis records and sum them up"
	def run(_mix_args) do
		records=do_analyze
		total_percent=Enum.reduce(records, 0.0, &(&1.percent+&2))
		IO.puts "total = #{total_percent}"
	end
end
