# Module to test InputParser

defmodule InputParserTest do
	use ExUnit.Case

	test "Populate data structures" do
		assert {:ok, pid}=InputParser.start_link

		#stn_map = InputParser.get_station_map(pid)
		#for stn_key <- Map.keys(stn_map) do
		#  IO.puts Map.get(stn_map, stn_key)
		#end

		code=InputParser.get_city_code(pid, "Alnavar Junction")
		assert code==5
		assert InputParser.get_local_variables(pid, code)==
		%{congestion: "low", delay: 0.22, disturbance: "no"}
		#assert InputParser.get_schedule(pid, code)==[%{arrival_time: 45000,
		# dept_time: 900, dst_station: 2, mode_of_transport: "train",
		# src_station: 5, vehicleID: 11043}, %{arrival_time: 63300, dept_time:
		# 300, dst_station: 7, mode_of_transport: "train", src_station: 5,
		# vehicleID: 19019}]
		# assert InputParser.get_station_struct(pid, "Alnavar Junction")==
		#%StationStruct{locVars: %{congestion: "low", congestionDelay: nil,
		# delay: 0.22, disturbance: "no"}, pid: nil, schedule: [%{arrival_time:
		# 45000, dept_time: 900, dst_station: 2, mode_of_transport: "train",
		# src_station: 5, vehicleID: 11043}, %{arrival_time: 63300, dept_time:
		# 300, dst_station: 7, mode_of_transport: "train", src_station: 5,
		# vehicleID: 19019}], station_name: "Alnavar Junction", station_number:
		# 5, choose_fn: 1, congestion_high: 3, congestion_low: 2}
		InputParser.stop(pid)
	end

end
