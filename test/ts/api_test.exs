defmodule APITest do
  use ExUnit.Case
  use Maru.Test, for: API

  test "/ v1" do
    assert "hello" = get("/", "v1") |> text_response
  end

  test "/ v2" do
    assert %{"hello" => "world"} = get("/", "v2") |> json_response
  end

  test "/ schedule" do
     assert %{"choose_fn" => 1, "congestion_high" => nil, "congestion_low" => 4, "locVars" => %{"congestion" => "low", "delay" => 0.38, "disturbance" => "no"}, "pid" => nil, "schedule" => [], "station_name" => nil, "station_number" => nil} =  get("/", "schedule") |> json_response
  end
end
