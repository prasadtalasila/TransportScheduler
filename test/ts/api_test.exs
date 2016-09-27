defmodule APITest do
  use ExUnit.Case, async: true
  use Plug.Test

  @opts API.init([])

  test "returns hello world" do
    # Create a test connection
    conn = conn(:get, "/hello")

    # Invoke the plug
    conn = API.call(conn, @opts)

    # Assert the response and status
    assert conn.state == :sent
    assert conn.status == 200
    assert conn.resp_body == "world"
  end

  test "returns schedule" do
    # Create a test connection
    conn = conn(:get, "/schedule?stn_code=1")

    # Invoke the plug
    conn = API.call(conn, @opts)

    # Assert the response and status
    assert conn.state == :sent
    assert conn.status == 200
    assert conn.resp_body == "[{\"vehicleID\":19019,\"src_station\":5,\"mode_of_transport\":\"train\",\"dst_station\":7,\"dept_time\":300,\"arrival_time\":63300}]"
  end

end


#
# PATH: /
# QUERY STRING: stn_code=1
# QUERY PARAMS: [ stn_code: 1 ]
#http://localhost:4000/schedule?stn_code=1


#  test "/schedule2/stn_code" do
#    assert [%{"arrival_time" => 63300, "dept_time" => 300, "dst_station" => 7,
#              "mode_of_transport" => "train", "src_station" => 5,
#              "vehicleID" => 19019}] =  get("/schedule2", "/stn_code=1") |> json_response
#  end

