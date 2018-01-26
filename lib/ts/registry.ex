defmodule TS.Registry do
	@moduledoc """
	Implements the interface of the Network Constructor.
	"""
	@callback lookup_code(String.t()) :: pid()
	@callback check_active(map()) :: boolean()
end
