defmodule Util.ItineraryBehaviour do
  @moduledoc """
  Defines the behaviour expected from the Itinerary module
  """
  @callback update_days_travelled(itinerary :: any()) :: any()
  @callback valid_itinerary_iterator(any(), any()) :: any()
  @callback next_itinerary(itinerary_iterator :: any()) :: any()
  @callback get_query_id(itinerary :: any()) :: any()
  @callback is_empty(itinerary :: any()) :: any()
  @callback is_terminal(itinerary :: any()) :: any()
  @callback is_valid_destination(
              station_number :: integer(),
              itinerary :: any()
            ) :: any()
end
