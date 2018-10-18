defmodule Network.Application do
  @moduledoc """
  Documentation for Network Constructor.
  """
  use Application
  alias Station.QueryCollector, as: QueryCollector
  alias Station.Registry, as: Registry
  alias Util.Dependency, as: Dependency
  alias Util.Itinerary, as: Itinerary

  def start(_type, _args) do
    [tuple] = Supervisor.which_children(InputParser.Supervisor)
    ip_pid = elem(tuple, 1)

    stn_map = InputParser.get_station_map(ip_pid)

    dependency = %Dependency{
      station: Station,
      registry: Registry,
      collector: QueryCollector,
      itinerary: Itinerary
    }

    children = [
      {DynamicSupervisor,
       name: Network.StationSupervisor, strategy: :one_for_one}
    ]

    opts = [strategy: :one_for_one, name: Network.Supervisor]

    {:ok, main_sup_pid} = Supervisor.start_link(children, opts)

    for stn_key <- Map.keys(stn_map) do
      stn_code = Map.get(stn_map, stn_key)
      stn_struct = InputParser.get_station_struct(ip_pid, stn_key)

      {:ok, stn_pid} =
        DynamicSupervisor.start_child(Network.StationSupervisor, %{
          id: Station,
          start: {Station, :start_link, [[stn_struct, dependency]]}
        })

      new_stn_struct = stn_struct |> Map.put(:pid, stn_pid)
      Station.update(stn_pid, new_stn_struct)
    end

    {:ok, main_sup_pid}
  end
end
