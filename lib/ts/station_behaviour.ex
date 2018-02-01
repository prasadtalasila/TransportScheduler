defmodule TS.StationBehaviour do
	@moduledoc """
	Defines the interface of a Station.
	"""
	@callback update(pid, struct) :: any()
	@callback get_timetable(pid()) :: any()
	@callback send_query(pid(), any()) :: any()

end
