# defmodule API do
#   use Maru.Router

#   version "v1" do
#     get do
#       text(conn, "hello")
#     end 
#   end
  
#   version "v2" do
#     get do
#       json(conn, %{hello: :world})
#     end 
#   end
  
#   version "schedule" do
#     get do
#       schedule =[%{arrival_time: 63300, dept_time: 300, dst_station: 7, mode_of_transport: "train", src_station: 5, vehicleID: 19019}]
#       json(conn, schedule)
#     end 
#   end

# end

defmodule API do
  import Plug.Conn
  use Plug.Router

  @userid   "uid"
  @password "pwd"

  @stn_code   "stn_code"

  plug :match
  plug :dispatch

  # Root path
  get "/" do
    conn = fetch_query_params(conn)
    %{ @userid => usr, @password => pass } = conn.params
    send_resp(conn, 200, "Hello #{usr}. Your password is #{pass}")
  end

  get "/hello" do
    send_resp(conn, 200, "world")
  end

  get "/schedule" do
    conn = fetch_query_params(conn)
    %{ @stn_code => stn_code } = conn.params

    schedule =[%{arrival_time: 63300, dept_time: 300, dst_station: 7, mode_of_transport: "train", src_station: 5, vehicleID: 19019}]

    # {:ok, {code, station}} = StationConstructor.lookup(registry, "Alnavar Junction")
    #schedule = Station.get_vars(station)

    send_resp(conn, 200, Poison.encode!(schedule))
  end

  match _ do
    send_resp(conn, 404, "oops")
  end
end


#PATH: /
#QUERY STRING: uid=ToddFlanders&pwd=MyTestPword
#QUERY PARAMS: [ uid: "ToddFlanders", pwd: "MyTestPword" ]
#http://localhost:4000/?uid=ToddFlanders&pwd=MyTestPword

#
# PATH: /
# QUERY STRING: stn_code=1
# QUERY PARAMS: [ stn_code: 1 ]
#http://localhost:4000/schedule?stn_code=1
