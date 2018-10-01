defmodule InputParser.InputParserBehaviour do
  @moduledoc """
  Defines the interface of the input parser.
  """
  @callback get_station_map(pid :: pid()) :: any()
  @callback get_schedules(pid :: pid()) :: any()
  @callback get_schedule(pid :: pid(), String.t()) :: any()
  @callback get_other_means(pid :: pid(), String.t()) :: any()
  @callback get_local_variables(pid :: pid(), String.t()) :: any()
  @callback get_city_code(pid :: pid(), String.t()) :: any()
  @callback get_station_struct(pid :: pid(), String.t()) :: any()
  @callback obtain_stations() :: any()
  @callback obtain_schedules() :: any()
  @callback obtain_other_means() :: any()
  @callback obtain_loc_var_map() :: any()
end
