defmodule StationBehaviour do
	@callback get_vars(pid) :: {:next_state, term, term, term}
	@callback get_state(pid) :: {:next_state, term, term, term}
	@callback update(pid, struct) :: {:next_state, term, term} 
	@callback receive_at_src(pid, pid, list) :: {:ok}
	@callback send_to_stn(pid, pid, pid) :: {:ok}
end