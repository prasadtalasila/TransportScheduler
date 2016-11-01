# Module to test Registry

defmodule StationConstructorTest do
  use ExUnit.Case, async: true

  setup do
    {:ok, registry} = StationConstructor.start_link
    {:ok, registry: registry}
  end

  test "spawns stations", %{registry: registry} do
    assert StationConstructor.lookup(registry, "VascoStation") == :error

    assert StationConstructor.create(registry, "VascoStation", 12) == :ok
    {:ok, pid} = StationConstructor.lookup(registry, "VascoStation")
  end

  test "spawns from InputParser", %{registry: registry} do
    assert {:ok, pid} = InputParser.start_link(10)

    stn_map = InputParser.get_station_map(pid)
    stn_sched = InputParser.get_schedules(pid)
    for stn_key <- Map.keys(stn_map) do
      stn_code = Map.get(stn_map, stn_key)
      stn_struct = InputParser.get_station_struct(pid, stn_key)

      assert StationConstructor.create(registry, stn_key, stn_code) == :ok
      {:ok, {code, station}} = StationConstructor.lookup(registry, stn_key)
      #IO.puts Station.get_state(station)
      Station.update(station, %StationStruct{})
      #IO.puts Station.get_state(station)
      Station.update(station, stn_struct)
     
    end

    {:ok, {code, stn}} = StationConstructor.lookup(registry, "Alnavar Junction")

    assert Station.get_vars(stn) ==   %StationStruct{choose_fn: 1, congestion_high: 3, congestion_low: 2, pid: nil, station_name: nil, station_number: nil, locVars: %{congestion: "low", congestionDelay: 0.44, delay: 0.22, disturbance: "no"}, schedule: [%{arrival_time: 45000, dept_time: 900, dst_station: 2, mode_of_transport: "train", src_station: 5, vehicleID: 11043}, %{arrival_time: 63300, dept_time: 300, dst_station: 7, mode_of_transport: "train", src_station: 5, vehicleID: 19019}]}

  end


  test "messages" do
    {_, p1}=Station.start_link
    Station.update(p1, %StationStruct{locVars: %{"delay": 0.01, "congestion": "low", "disturbance": "no"}, schedule: [], congestion_low: 4, choose_fn: 1, station_number: 1})
    {_, p2}=Station.start_link
   Station.update(p1, %StationStruct{locVars: %{"delay": 0.02, "congestion": "low", "disturbance": "no"}, schedule: [], congestion_low: 4, choose_fn: 1, station_number: 2})
    {_, nc}=StationConstructor.start_link
    assert StationConstructor.send_message_stn(nc, p1)==:msg_sent_to_stn
    assert Station.send_message_stn(p1, p2)==:msg_sent_to_stn
    #Get StationConstructor to receive messages
    #assert Station.send_message_NC(p2, nc)==:msg_sent_to_NC

  end

end


