defmodule Station.Registry do
  @moduledoc """
  Acts as the registry for any data that should be managed globally in the application.
  This includes the mapping between station code to station pid and query id to query status.
  """
  use GenServer, async: true
  require Logger
  @behaviour Station.RegistryBehaviour

  # Starts the Registry process with the name, name.
  def start_link do
    GenServer.start_link(__MODULE__, :ok, name: :registry)
  end

  def init(:ok) do
    Logger.debug(fn -> "Starting Registry" end)
    {:ok, nil}
  end

  def stop(pid) do
    Logger.debug(fn -> "Terminating Registry normally" end)
    GenServer.stop(pid, :normal)
  end

  # Returns the station pid associated with the station code
  def lookup_code(station_code) do
    stations = :pg2.get_members({:station_code, station_code})

    if is_list(stations) and stations != [] do
      neighbour_pid = List.first(stations)

      Logger.debug(fn ->
        "Station code lookup #{station_code} -> #{neighbour_pid}"
      end)

      neighbour_pid
    else
      Logger.debug(fn -> "Station code lookup failed for #{station_code}" end)
      nil
    end
  end

    # Returns the Query Collecotr pid associated with the query id
    def lookup_query_id(qid) do
      qc = :pg2.get_members({:qid, qid})

      if is_list(qc) and qc != [] do
        qc_pid = List.first(qc)

        Logger.debug(fn ->
          "Query ID lookup #{qid} -> #{qc_pid}"
        end)

        qc_pid
      else
        Logger.debug(fn -> "Query ID lookup failed for #{qid}" end)
        nil
      end
    end

  # Checks whether the query is active. If there is no query collector
  # process associated with the qid process group it is assumed that the query
  # has gone stale
  def check_active(qid) do
    qc = :pg2.get_members({:qid, qid})

    active =
      if is_list(qc) and qc != [] do
        true
      else
        false
      end

    if active do
      Logger.debug(fn -> "Query #{qid} is active" end)
    else
      Logger.debug(fn -> "Query #{qid} is inactive" end)
    end

    active
  end

  # Registers station code to station pid mapping globally.
  def register_station(station_code, station_pid) do
    Logger.debug(fn ->
      "Registering station #{station_code} as #{station_pid}"
    end)

    register_name({:station_code, station_code}, station_pid)
  end

  # Unregisters the station group designated by the station code globally
  def unregister_station(station_code) do
    Logger.debug(fn -> "Unregistering station #{station_code}" end)
    unregister_group({:station_code, station_code})
  end

  # Registers query id to query collector pid mapping globally.
  def register_query(qid, qc_pid) do
    Logger.debug(fn -> "Registering Query #{qid} as #{qc_pid}" end)
    register_name({:qid, qid}, qc_pid)
  end

  # Marks a query as stale by unregistering it globally.
  def unregister_query(qid) do
    Logger.debug(fn -> "Unregistering Query #{qid}" end)
    unregister_group({:qid, qid})
  end

  # Registers a given group to pid mapping
  def register_name(group, pid) when is_pid(pid) do
    GenServer.call(:registry, {:register_name, group, pid})
  end

  # Unregisters group to pid mapping. The group is not removed
  def unregister_name(group, pid) when is_pid(pid) do
    GenServer.call(:registry, {:unregister_name, group, pid})
  end

  # Removes the group globally in the application
  def unregister_group(group) do
    GenServer.call(:registry, {:unregister_group, group})
  end

  def handle_call({:register_name, group, pid}, _from, nil) do
    :pg2.create(group)
    :pg2.join(group, pid)
    {:reply, :ok, nil}
  end

  def handle_call({:unregister_name, group, pid}, _from, nil) do
    :pg2.leave(group, pid)
    {:reply, :ok, nil}
  end

  def handle_call({:unregister_group, group}, _from, nil) do
    :pg2.delete(group)
    {:reply, :ok, nil}
  end
end
