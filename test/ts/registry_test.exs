# Module to test Registry

defmodule RegistryTest do
  use ExUnit.Case, async: true

  setup do
    {:ok, registry} = Registry.start_link
    {:ok, registry: registry}
  end

  test "spawns stations", %{registry: registry} do
    assert Registry.lookup(registry, "VascoStation") == :error

    Registry.create(registry, "VascoStation")
    assert {:ok, station} = Registry.lookup(registry, "VascoStation")
  end

  
end


