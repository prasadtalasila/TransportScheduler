defmodule LocVarMapTest do
  use ExUnit.Case
  
	test "get data" do
		assert {:ok, pid} = LocVarMap.init
		assert LocVarMap.get_data(pid, {{2016, 8, 14}, {8, 00}}) == %{congestion: "high", delay: 0.38, disturbance: "no"}
	end
	
end
