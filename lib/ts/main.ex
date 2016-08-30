defmodule Main do
  def main(args \\ []) do

    {:ok, registry} = Registry.start_link
    {:ok, registry: registry}

    Registry.lookup(registry, "VascoStation")

    Registry.create(registry, "VascoStation")
    {:ok, station} = Registry.lookup(registry, "VascoStation")


    Station.update(station, ss = %StationStruct{locVars: %{"delay": 0.38, "congestion": "low", "disturbance": "no"}, schedule: [], congestion_low: "delay * 4"})

    IO.puts "Original delay value:"
    IO.puts Station.get_vars(station).locVars.delay
    IO.puts "After congestion delay value:"
    IO.puts Station.get_vars(station).locVars.congestionDelay
    
  end

end


