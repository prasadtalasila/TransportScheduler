defmodule APITest do
  use ExUnit.Case
  use Maru.Test, for: API

  test "/v1" do
    assert "hello" = get("/", "v1") |> text_response
  end

  test "/v2" do
    assert %{"hello" => "world"} = get("/", "v2") |> json_response
  end

  test "/schedule" do
    assert [%{"arrival_time" => 63300, "dept_time" => 300, "dst_station" => 7,
              "mode_of_transport" => "train", "src_station" => 5,
              "vehicleID" => 19019}] =  get("/", "schedule") |> json_response
  end

#
# PATH: /
# QUERY STRING: stn_code=1
# QUERY PARAMS: [ stn_code: 1 ]
#

#  test "/schedule2/stn_code" do
#    assert [%{"arrival_time" => 63300, "dept_time" => 300, "dst_station" => 7,
#              "mode_of_transport" => "train", "src_station" => 5,
#              "vehicleID" => 19019}] =  get("/schedule2", "/stn_code=1") |> json_response
#  end
end
