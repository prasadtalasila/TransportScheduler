# Module to test InputParser

defmodule InputParserTest do
  use ExUnit.Case
  
  test "populate data structures" do
    assert {:ok, pid} = InputParser.start_link(10)
    code=InputParser.get_city_code(pid, "Alnavar Junction")
    assert code==5
    assert InputParser.get_local_variables(pid, code)==%{congestion: "low", delay: 0.22, disturbance: "no"}
    assert InputParser.get_schedule(pid, code)==[%{arrival_time: 45000, dept_time: 900, dst_station: 2, mode_of_transport: "train", src_station: 5, vehicleID: 11043},
    %{arrival_time: 63300, dept_time: 300, dst_station: 7, mode_of_transport: "train", src_station: 5, vehicleID: 19019}]
    assert InputParser.get_station_struct(pid, "Alnavar Junction")==%StationStruct{choose_fn: nil, congestion_high: nil, congestion_low: nil, 
    locVars: %{congestion: "low", congestionDelay: nil, delay: 0.22, disturbance: "no"}, pid: nil, schedule: [%{arrival_time: 45000, dept_time: 900, dst_station: 2,
    mode_of_transport: "train", src_station: 5, vehicleID: 11043}, %{arrival_time: 63300, dept_time: 300, dst_station: 7, mode_of_transport: "train", src_station: 5, 
    vehicleID: 19019}], station_name: "Alnavar Junction", station_number: 5}
    InputParser.stop(pid)
  end
  
end
