defmodule Main do
  def main(args \\ []) do

    # {:ok, registry} = Registry.start_link
    # {:ok, registry: registry}

    # Registry.lookup(registry, "VascoStation")

    # Registry.create(registry, "VascoStation")
    # {:ok, station} = Registry.lookup(registry, "VascoStation")

    {:ok, station} = Station.start_link

    Station.update(station, ss = %StationStruct{locVars: %{"delay": 0.38, "congestion": "low", "disturbance": "no"}, schedule: [%{vehicleID: 12959, src_station: 1, dst_station: 2, dept_time: nil, arrival_time: nil, mode_of_transport: "train"}], station_number: 1, station_name: "VascoStation", congestion_low: 2, congestion_high: 3})

    IO.puts "Original delay value:"
    IO.puts Station.get_vars(station).locVars.delay
    IO.puts "After congestion delay value:"
    IO.puts Station.get_vars(station).locVars.congestionDelay
    
  end

end


