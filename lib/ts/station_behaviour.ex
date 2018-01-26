defmodule StationBehaviour do
	@moduledoc """
	Defines the interface of a Station.
	"""
	@callback get_vars(pid) :: {:next_state, term, term, term}
	@callback get_state(pid) :: {:next_state, term, term, term}
	@callback update(pid, struct) :: {:next_state, term, term}
end
