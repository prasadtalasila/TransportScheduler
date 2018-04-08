defmodule MultiplierTest do
  use ExUnit.Case
  doctest Multiplier

  test "greets the world" do
    assert Multiplier.hello() == :world
  end
end
