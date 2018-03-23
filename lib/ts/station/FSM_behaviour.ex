defmodule Station.FSMBehaviour do
  @moduledoc """
  Defines the interface of Station.Fsm.
  """
  @callback initialise_fsm(input :: any()) :: any()
  @callback update_station(
              station_fsm :: any(),
              new_station_struct :: any()
            ) :: any()
  @callback process_itinerary(station_fsm :: any(), itinerary :: any()) ::
              any()
  @callback get_timetable(station_fsm :: any()) :: any()
end
