defmodule Station.CollectorBehaviour do
  @moduledoc """
  Defines the interface for the Query Collector.
  """
  @callback collect(list(), any()) :: any()
end
