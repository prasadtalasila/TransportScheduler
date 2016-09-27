# Module to test Registry

defmodule StationConstructorTest do
  use ExUnit.Case, async: true

  setup do
    {:ok, registry} = StationConstructor.start_link
    {:ok, registry: registry}
  end

  test "spawns stations", %{registry: registry} do
    assert StationConstructor.lookup(registry, "VascoStation") == :error

    assert StationConstructor.create(registry, "VascoStation", 12) == :ok
    {:ok, pid} = StationConstructor.lookup(registry, "VascoStation")
  end

  test "spawns from InputParser", %{registry: registry} do
    assert {:ok, pid} = InputParser.start_link(10)

    stn_map = InputParser.get_station_map(pid)
    stn_sched = InputParser.get_schedules(pid)
    for stn_key <- Map.keys(stn_map) do
      stn_code = Map.get(stn_map, stn_key)
      stn_struct = InputParser.get_station_struct(pid, stn_key)

      assert StationConstructor.create(registry, stn_key, stn_code) == :ok
      {:ok, {code, station}} = StationConstructor.lookup(registry, stn_key)

      #assert Station.update(station, stn_struct) == :ok
      # BUG NEEDS FIX: update causes pid used afterwards to get messed up (???)
    end

    {:ok, {code, stn}} = StationConstructor.lookup(registry, "Alnavar Junction")

    # assert Station.get_vars(stn) == 2

  end
end


