defmodule APITest do
  use ExUnit.Case, async: true
  use Maru.Test, for: API

  test "returns welcome message" do
    assert "Welcome to TransportScheduler API" == get("/api")|>text_response
  end

  setup do
    conn=build_conn()|>put_req_header("content-type", "application/json")
    |>put_plug(Plug.Parsers, parsers: [:json], pass: ["*/*"], json_decoder: Poison)
    {:ok, %{conn: conn}}
  end

  test "returns schedule", %{conn: conn} do
    assert %Plug.Conn{}=conn|>put_body_or_params(~s({"source": 5, "date": "1/11/2016"}))|>get("/api/station/schedule")

    # Assert the response and status
    #assert conn.state == :sent
    #assert conn.status == 200
    #assert conn.resp_body == "[{\"vehicleID\":19019,\"src_station\":5,\"mode_of_transport\":\"train\",\"dst_station\":7,\"dept_time\":300,\"arrival_time\":63300}]"
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

