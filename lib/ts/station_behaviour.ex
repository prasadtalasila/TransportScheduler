defmodule StationBehaviour do
	@moduledoc """
	Defines the interface of a Station.
	"""
	@callback update(pid, struct) :: any()
	@callback get_timetable(pid()) :: any()

end
