defmodule SupervisorTest do
	@moduledoc """
	Module to test Supervisors
	"""
	use ExUnit.Case, async: true

	test "Crash processes and restart" do
		assert NetworkConstructor.create(NetworkConstructor, "TestStationProcess", 1)==:ok
		{:ok, {_, pid}}=NetworkConstructor.lookup_name(NetworkConstructor,
			"TestStationProcess")
		ref=Process.monitor(pid)
		Process.exit(pid, :shutdown)
		assert_receive {:DOWN, ^ref, _, _, _}
		NetworkConstructor.stop(NetworkConstructor)
		NetworkConstructor.create(NetworkConstructor, "TestStationProcess", 1)
	end
end
