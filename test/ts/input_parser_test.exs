defmodule InputParserTest do
	@moduledoc """
	Module to test InputParser
	"""
	use ExUnit.Case

	test "Populate data structures" do
		assert {:ok, pid}=InputParser.start_link
		code=InputParser.get_city_code(pid, "Alnavar Junction")
		assert code==5
		assert InputParser.get_local_variables(pid, code)==
		%{congestion: "low", delay: 0.22, disturbance: "no"}
		assert InputParser.get_schedule(pid, code)==
			[%{arrival_time: 78180, dept_time: 74700, dst_station: 6,
				mode_of_transport: "train", src_station: 5, vehicleID: "16590"},
			%{arrival_time: 66000, dept_time: 63600, dst_station: 6,
				mode_of_transport: "train", src_station: 5, vehicleID: "17416"},
			%{arrival_time: 66600, dept_time: 62100, dst_station: 4,
				mode_of_transport: "train", src_station: 5, vehicleID: "17305"},
			%{arrival_time: 61080, dept_time: 58800, dst_station: 4,
				mode_of_transport: "train", src_station: 5, vehicleID: "11036"},
			%{arrival_time: 61080, dept_time: 58800, dst_station: 4,
				mode_of_transport: "train", src_station: 5, vehicleID: "11022"},
			%{arrival_time: 61080, dept_time: 58800, dst_station: 4,
				mode_of_transport: "train", src_station: 5, vehicleID: "11006"},
			%{arrival_time: 41100, dept_time: 38400, dst_station: 6,
				mode_of_transport: "train", src_station: 5, vehicleID: "11035"},
			%{arrival_time: 41100, dept_time: 38400, dst_station: 6,
				mode_of_transport: "train", src_station: 5, vehicleID: "11021"},
			%{arrival_time: 41100, dept_time: 38400, dst_station: 6,
				mode_of_transport: "train", src_station: 5, vehicleID: "11005"},
			%{arrival_time: 37380, dept_time: 35220, dst_station: 4,
				mode_of_transport: "train", src_station: 5, vehicleID: "17415"},
			%{arrival_time: 26880, dept_time: 24600, dst_station: 4,
				mode_of_transport: "train", src_station: 5, vehicleID: "16589"},
			%{arrival_time: 19500, dept_time: 15600, dst_station: 6,
				mode_of_transport: "train", src_station: 5, vehicleID: "12780"},
			%{arrival_time: 19500, dept_time: 15600, dst_station: 6,
				mode_of_transport: "train", src_station: 5, vehicleID: "11047"},
			%{arrival_time: 6180, dept_time: 3000, dst_station: 4,
				mode_of_transport: "train", src_station: 5, vehicleID: "17309"},
			%{arrival_time: 4080, dept_time: 1800, dst_station: 6,
				mode_of_transport: "train", src_station: 5, vehicleID: "17310"}]
		assert InputParser.get_station_struct(pid, "kanpur")==%StationStruct{
			choose_fn: 1, congestion_high: 3, congestion_low: 2, loc_vars: %{
				congestion: "low", congestion_delay: nil, delay: 0.38,
				disturbance: "no"}, other_means: [%{dst_station: 1648, src_station:
				2188, travel_time: 3169}, %{dst_station: 1647, src_station: 2188,
				travel_time: 1800}, %{dst_station: 153, src_station: 2188, travel_time:
				994}, %{dst_station: 152, src_station: 2188, travel_time: 1754}], pid:
			nil, schedule: [%{arrival_time: 110700, dept_time: 81600, dst_station:
				398, mode_of_transport: "bus", src_station: 2188, vehicleID: "4563699"},
				%{arrival_time: 112500, dept_time: 79800, dst_station: 398,
					mode_of_transport: "bus", src_station: 2188, vehicleID: "4563697"},
				%{arrival_time: 109800, dept_time: 68400, dst_station: 757,
					mode_of_transport: "bus", src_station: 2188, vehicleID: "4651629"},
				%{arrival_time: 121800, dept_time: 59400, dst_station: 2223,
					mode_of_transport: "bus", src_station: 2188, vehicleID: "4325536"},
				%{arrival_time: 61500, dept_time: 58200, dst_station: 785,
					mode_of_transport: "flight", src_station: 2188, vehicleID: "9606_CRJ700"},
				%{arrival_time: 48600, dept_time: 43200, dst_station: 2152,
					mode_of_transport: "flight", src_station: 2188, vehicleID: "9605_CRJ700"},
				%{arrival_time: 46500, dept_time: 43200, dst_station: 785,
					mode_of_transport: "flight", src_station: 2188, vehicleID: "9606_CRJ700"},
				%{arrival_time: 65700, dept_time: 36600, dst_station: 398,
					mode_of_transport: "bus", src_station: 2188, vehicleID: "4563703"},
				%{arrival_time: 39900, dept_time: 29700, dst_station: 785,
					mode_of_transport: "flight", src_station: 2188, vehicleID: "9811_ATR42-3"},
				%{arrival_time: 32100, dept_time: 29700, dst_station: 2138,
					mode_of_transport: "flight", src_station: 2188, vehicleID: "9811_ATR42-3"}],
			station_name: "kanpur", station_number: 2188}
		assert :ok===InputParser.stop(pid)
	end

end
