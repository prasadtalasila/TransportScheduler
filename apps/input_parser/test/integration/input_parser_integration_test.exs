defmodule InputParserIntegrationTest do
  use ExUnit.Case
  doctest InputParser

  test "greets the world" do
    assert InputParser.hello() == :world
  end
end
