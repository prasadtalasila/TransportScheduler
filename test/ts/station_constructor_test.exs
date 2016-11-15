# Module to test Registry

defmodule StationConstructorTest do
  use ExUnit.Case, async: true

  setup do
    {:ok, registry} = StationConstructor.start_link
    {:ok, registry: registry}
  end

  test "spawns stations", %{registry: registry} do
    assert StationConstructor.lookup_name(registry, "VascoStation") == :error

    assert StationConstructor.create(registry, "VascoStation", 12) == :ok
    {:ok, pid} = StationConstructor.lookup_name(registry, "VascoStation")
  end

  test "spawns from InputParser", %{registry: registry} do
    assert {:ok, pid} = InputParser.start_link(10)

    stn_map = InputParser.get_station_map(pid)
    stn_sched = InputParser.get_schedules(pid)
    for stn_key <- Map.keys(stn_map) do
      stn_code = Map.get(stn_map, stn_key)
      stn_struct = InputParser.get_station_struct(pid, stn_key)

      assert StationConstructor.create(registry, stn_key, stn_code) == :ok
      {:ok, {code, station}} = StationConstructor.lookup_name(registry, stn_key)
      #IO.puts Station.get_state(station)
      Station.Update.update(%Station{pid: station}, %StationStruct{})
      #IO.puts Station.get_state(station)
      Station.Update.update(%Station{pid: station}, stn_struct)
     
    end

    {:ok, {code, stn}} = StationConstructor.lookup_name(registry, "Alnavar Junction")

    assert Station.get_vars(stn) ==   %StationStruct{choose_fn: 1, congestion_high: 3, congestion_low: 2, pid: nil, station_name: nil, station_number: nil, locVars: %{congestion: "low", congestionDelay: 0.44, delay: 0.22, disturbance: "no"}, schedule: [%{arrival_time: 45000, dept_time: 900, dst_station: 2, mode_of_transport: "train", src_station: 5, vehicleID: 11043}, %{arrival_time: 63300, dept_time: 300, dst_station: 7, mode_of_transport: "train", src_station: 5, vehicleID: 19019}]}

  end


  test "messages" do
    {_, p1}=Station.start_link
    Station.Update.update(%Station{pid: p1}, ss = %StationStruct{locVars: %{"delay": 0.38, "congestion": "low", "disturbance": "no", "congestion_low": 4, "choose_fn": 1}, schedule: [%{vehicleID: 1111, src_station: 1, dst_station: 2, dept_time: "07:12:00", arrival_time: "16:32:00", mode_of_transport: "train"}, %{vehicleID: 2222, src_station: 1, dst_station: 2, dept_time: "13:12:00", arrival_time: "14:32:00", mode_of_transport: "train"}, %{vehicleID: 3333, src_station: 1, dst_station: 2, dept_time: "03:12:00", arrival_time: "10:32:00", mode_of_transport: "train"}, %{vehicleID: 4444, src_station: 1, dst_station: 2, dept_time: "19:12:00", arrival_time: "20:32:00", mode_of_transport: "train"}]})
    {_, p2}=Station.start_link
    Station.Update.update(%Station{pid: p2}, ss = %StationStruct{locVars: %{"delay": 0.38, "congestion": "low", "disturbance": "no", "congestion_low": 4, "choose_fn": 1}, schedule: [%{vehicleID: 5555, src_station: 2, dst_station: 3, dept_time: "17:12:00", arrival_time: "19:32:00", mode_of_transport: "train"}]})
    {_, nc}=StationConstructor.start_link
    itinerary  = [%{src_station: 1, dst_station: 3, arrival_time: "04:42:00"}]
    {:msg_received_at_src, it1} = StationConstructor.send_to_src(nc, p1, itinerary)
    #IO.puts it1
    {:msg_received_at_stn, it2} = Station.send_to_stn(p1, p2, it1)
    #IO.puts it2
    #Get StationConstructor to receive messages
    #assert Station.send_message_NC(p2, nc)==:msg_sent_to_NC

  end

end


