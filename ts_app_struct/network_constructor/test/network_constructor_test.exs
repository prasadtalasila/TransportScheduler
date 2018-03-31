defmodule NetworkConstructorTest do
  use ExUnit.Case
  doctest NetworkConstructor

  test "greets the world" do
    assert NetworkConstructor.hello() == :world
  end
end
