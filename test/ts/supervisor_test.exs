defmodule SupervisorTest do
	@moduledoc """
	Module to test Supervisors
	"""
	use ExUnit.Case, async: true

	test "Crash processes and restart" do
		assert StationConstructor.create(StationConstructor, "TestStationProcess", 1)==:ok
		{:ok, {_, pid}}=StationConstructor.lookup_name(StationConstructor,
			"TestStationProcess")
		ref = Process.monitor(pid)
		Process.exit(pid, :shutdown)
		assert_receive {:DOWN, ^ref, _, _, _}

		assert StationConstructor.lookup_name(StationConstructor,
			"TestStationProcess") == :error

		StationConstructor.create(StationConstructor, "TestStationProcess", 1)
		{:ok, {_, _}}=StationConstructor.lookup_name(StationConstructor,
			"TestStationProcess")


		StationConstructor.stop(StationConstructor)
		StationConstructor.create(StationConstructor, "TestStationProcess", 1)

		
	end

end
