defmodule UtilTest do
  use ExUnit.Case
  doctest Util

  test "greets the world" do
    assert Util.hello() == :world
  end
end
