defmodule Station.RegistryBehaviour do
  @moduledoc """
  Implements the interface of the Network Constructor.
  """
  @callback lookup_code(String.t()) :: pid()
  @callback lookup_query_id(String.t()) :: pid()
  @callback check_active(any()) :: boolean()
  @callback register_station(any(), pid()) :: any()
  @callback register_query(any(), pid()) :: any()
  @callback unregister_station(any()) :: any()
  @callback unregister_query(any()) :: any()
end
