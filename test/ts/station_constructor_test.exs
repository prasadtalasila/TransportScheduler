# Module to test StationConstructor
# Create new NC process and add stations to its registry
# Use InputParser to create new stations
# Use message passing to find best itinerary

defmodule StationConstructorTest do
	use ExUnit.Case, async: true

	test "Start new NC and add new Station process" do
		assert StationConstructor.lookup_name(StationConstructor, "VascoStation")==
		:error
		assert StationConstructor.create(StationConstructor, "TestStation", 12)==:ok
		{:ok, pid}=StationConstructor.lookup_name(StationConstructor,
			"TestStation")
	end

	test "Add new Stations using InputParser" do
		assert {:ok, pid}=InputParser.start_link
		stn_map=InputParser.get_station_map(pid)
		stn_sched=InputParser.get_schedules(pid)
		for stn_key<-Map.keys(stn_map) do
			stn_code=Map.get(stn_map, stn_key)
			stn_struct=InputParser.get_station_struct(pid, stn_key)
			assert StationConstructor.create(StationConstructor, stn_key, stn_code)==
			:ok
			{:ok, {code, station}}=StationConstructor.lookup_name(StationConstructor,
				stn_key)
			#IO.puts Station.get_state(station)
			Station.update(station, %StationStruct{})
			#IO.puts Station.get_state(station)
			Station.update(station, stn_struct)
		end
		{:ok, {code, stn}}=StationConstructor.lookup_name(StationConstructor,
			"Alnavar Junction")
	end

	test "Complete test" do
		assert {:ok, pid}=InputParser.start_link
		stn_map=InputParser.get_station_map(pid)
		stn_sched=InputParser.get_schedules(pid)
		for stn_key<-Map.keys(stn_map) do
			stn_code=Map.get(stn_map, stn_key)
			stn_struct=InputParser.get_station_struct(pid, stn_key)
			assert StationConstructor.create(StationConstructor, stn_key, stn_code)==
			:ok
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
