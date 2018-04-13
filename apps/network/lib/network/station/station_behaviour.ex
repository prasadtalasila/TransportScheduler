defmodule Station.StationBehaviour do
  @moduledoc """
  Defines the interface of a Station.
  """
  @callback get_timetable(pid :: pid()) :: any()
  @callback update(pid :: pid(), struct :: any()) :: any()
  @callback send_query(pid(), any()) :: any()
end
