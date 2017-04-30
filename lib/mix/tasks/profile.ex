defmodule Mix.Tasks.Profile do
	@moduledoc """
	Helper module to run profiling code using ExProf.
	"""
	use Mix.Task
	import ExProf.Macro

	@doc """
	Runs the Profile task with the given args to analyze the enclosed code.

	### Return values
	If the task was not yet invoked, it runs the task and returns the result.
	If there is an alias with the same name, the alias will be invoked instead
	of the original task. If the task or alias were already invoked, it does not
	run them again and simply aborts with :noop.
	"""
	def do_analyze do
		TS.Supervisor.start_link
		{:ok, pid}=InputParser.start_link
		stn_map=InputParser.get_station_map(pid)
		for stn_key<-Map.keys(stn_map) do
			stn_code=Map.get(stn_map, stn_key)
			stn_struct=InputParser.get_station_struct(pid, stn_key)
			StationConstructor.create(StationConstructor, stn_key, stn_code)
			{:ok, {_, station}}=StationConstructor.lookup_name(StationConstructor,
				stn_key)
			Station.update(station, stn_struct)
		end
		{:ok, {code1, stn1}}=StationConstructor.lookup_name(StationConstructor,
			"Madgaon")
		{:ok, {code2, _}}=StationConstructor.lookup_name(StationConstructor,
			"Ratnagiri")
		itinerary=[%{src_station: code1, dst_station: code2, arrival_time: 0,
			end_time: 86_400}]
		query=List.first(itinerary)
		API.start_link
		API.put("conn", query, [])
		API.put({"times", query}, [])
		StationConstructor.add_query(StationConstructor, query, "conn")
		itinerary=[Map.put(query, :day, 0)]
		{:ok, pid}=QC.start_link
		API.put(query, {self(), pid, System.system_time(:milliseconds)})
		profile do
			StationConstructor.send_to_src(StationConstructor, stn1, itinerary)
			Process.send_after(self(), :timeout, 500)
			receive do
			:timeout->
				StationConstructor.del_query(StationConstructor, query)
				_=API.get("conn")
				API.remove("conn")
				API.remove({"times", query})
				API.remove(query)
				QC.stop(pid)
			:release->
				_=API.get("conn")
				API.remove("conn")
				API.remove({"times", query})
				API.remove(query)
				QC.stop(pid)
			end
		end
	end

	@doc """
	Prints analysis results.
	"""
	def run(_mix_args) do
		records=do_analyze()
		total_percent=Enum.reduce(records, 0.0, &(&1.percent+&2))
		IO.puts "total = #{total_percent}"
	end
end
