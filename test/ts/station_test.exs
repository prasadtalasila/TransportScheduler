# Module to test Station
# Fails to link process with FSM

defmodule StationTest do
  use ExUnit.Case 

  test "initial state is nodata" do
    x = Station.new
    assert x.state == :nodata
    assert x.data == nil
  end

  test "new plus update 1" do
    x = Station.new |> Station.update(%{:delay => 0.38, :congestion => "high", :disturbance => "no"}) 
    assert x.state == :delay
    IO.puts x.data.delay
  end
  
  test "new plus update 2" do
    x = Station.new |> Station.update(%{:delay => 0.38, :congestion => "none", :disturbance => "yes"}) 
    assert x.state == :disturbance
    #IO.puts x.data
  end

end


