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
      schedule =[%{arrival_time: 63300, dept_time: 300, dst_station: 7, mode_of_transport: "train", src_station: 5, vehicleID: 19019}]
      json(conn, schedule)
    end 
  end

end
