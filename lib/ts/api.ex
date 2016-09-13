defmodule API do
  use Maru.Router

  version "v1" do
    get do
      text(conn, "hello")
    end 
  end
  
  version "v2" do
    get do
      json(conn, %{hello: :world})
    end 
  end
  
  version "schedule" do
    get do
      schedule = %StationStruct{locVars: %{"delay": 0.38, "congestion": "low", "disturbance": "no"}, schedule: [], congestion_low: 4, choose_fn: 1}
      json(conn, schedule)
    end 
  end

end
