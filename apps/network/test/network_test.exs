defmodule NetworkTest do
  use ExUnit.Case
  doctest Network

  test "greets the world" do
    assert Network.hello() == :world
  end
end
