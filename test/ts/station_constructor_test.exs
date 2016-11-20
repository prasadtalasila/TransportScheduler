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
      Station.update(station, %StationStruct{})
      #IO.puts Station.get_state(station)
      Station.update(station, stn_struct)
     
    end

    {:ok, {code, stn}} = StationConstructor.lookup_name(registry, "Alnavar Junction")

   # assert Station.get_vars(stn) ==   %StationStruct{choose_fn: 1, congestion_high: 3, congestion_low: 2, pid: nil, station_name: nil, station_number: nil, locVars: %{congestion: "low", congestionDelay: 0.44, delay: 0.22, disturbance: "no"}, schedule: [%{arrival_time: 45000, dept_time: 900, dst_station: 2, mode_of_transport: "train", src_station: 5, vehicleID: 11043}, %{arrival_time: 63300, dept_time: 300, dst_station: 7, mode_of_transport: "train", src_station: 5, vehicleID: 19019}]}

  end


  test "messages" do
    {_, nc}=StationConstructor.start_link
    StationConstructor.create(nc, "p1", 1) 
    StationConstructor.create(nc, "p2", 2) 
    StationConstructor.create(nc, "p3", 3) 
    {:ok, {_, p1}} = StationConstructor.lookup_name(nc, "p1")
    {:ok, {_, p2}} = StationConstructor.lookup_name(nc, "p2")
    {:ok, {_, p3}} = StationConstructor.lookup_name(nc, "p3")
    Station.update(p1, ss = %StationStruct{locVars: %{"delay": 0.38, "congestion": "low", "disturbance": "no", "congestion_low": 4, "choose_fn": 1}, schedule: [%{vehicleID: 1111, src_station: 1, dst_station: 3, dept_time: "07:12:00", arrival_time: "16:32:00", mode_of_transport: "train"}, %{vehicleID: 2222, src_station: 1, dst_station: 2, dept_time: "13:12:00", arrival_time: "14:32:00", mode_of_transport: "train"}, %{vehicleID: 3333, src_station: 1, dst_station: 2, dept_time: "03:12:00", arrival_time: "10:32:00", mode_of_transport: "train"}, %{vehicleID: 4444, src_station: 1, dst_station: 2, dept_time: "19:12:00", arrival_time: "20:32:00", mode_of_transport: "train"}]})
    Station.update(p2, ss = %StationStruct{locVars: %{"delay": 0.38, "congestion": "low", "disturbance": "no", "congestion_low": 4, "choose_fn": 1}, schedule: [%{vehicleID: 5555, src_station: 2, dst_station: 3, dept_time: "17:12:00", arrival_time: "19:32:00", mode_of_transport: "train"}]})

    itinerary  = [%{src_station: 1, dst_station: 3, arrival_time: "04:42:00"}]
    #StationConstructor.send_to_src(nc, p1, itinerary)
    itinerary2  = [%{src_station: 1, dst_station: 3, arrival_time: "04:42:00"}|%{vehicleID: 6666, src_station: 1, dst_station: 2, dept_time: "12:12:00", arrival_time: "19:32:00", mode_of_transport: "train"}]
   # Station.send_to_stn(nc, p1, p2, itinerary2)

    #Station.function(nc, p1, itinerary, %{vehicleID: 1111, src_station: 1, dst_station: 2, dept_time: "07:12:00", arrival_time: "16:32:00", mode_of_transport: "train"} )

    :timer.sleep(1000)

  end


  test "complete tests", %{registry: registry} do
    assert {:ok, pid} = InputParser.start_link(10)

    stn_map = InputParser.get_station_map(pid)
    stn_sched = InputParser.get_schedules(pid)
    for stn_key <- Map.keys(stn_map) do
      stn_code = Map.get(stn_map, stn_key)
      stn_struct = InputParser.get_station_struct(pid, stn_key)

      assert StationConstructor.create(registry, stn_key, stn_code) == :ok
      {:ok, {code, station}} = StationConstructor.lookup_name(registry, stn_key)
      #IO.puts Station.get_state(station)
      Station.update(station, %StationStruct{})
      #IO.puts Station.get_state(station)
      Station.update(station, stn_struct)
      
    end

    {:ok, {code, stn}} = StationConstructor.lookup_code(registry, 1)
    
    itinerary  = [%{src_station: 1, dst_station: 9, arrival_time: 200}]
    StationConstructor.send_to_src(registry, stn, itinerary)
    
    :timer.sleep(1000)

  end


end


