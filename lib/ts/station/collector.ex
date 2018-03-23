defmodule Station.Collector do
  @moduledoc """
  Defines the interface for the Query Collector.
  """
  @callback collect(list()) :: any()
end
