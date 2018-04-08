defmodule Station.UQCBehaviour do
  @moduledoc """
  Defines the interface expected from UQC
  """
  @callback receive_search_results(list()) :: any()
end
