# Module to create registry process for monitoring all station processes

defmodule StationConstructor do
  use GenServer

  ## Client API

  @doc """
  Starts the registry of transport stations.
  """
  def start_link do
    GenServer.start_link(__MODULE__, :ok, [])
  end

  @doc """
  Looks up the bucket pid for `name` stored in `server`.

  Returns `{:ok, pid}` if the station exists, `:error` otherwise.
  """
  def lookup(server, name) do
    GenServer.call(server, {:lookup, name})
  end

  @doc """
  Ensures there is a station associated to the given `name` in `server`.
  """
  def create(server, name, code) do
    GenServer.cast(server, {:create, name, code})
  end
  

  @doc """
  Stops the registry.
  """
  def stop(server) do
    GenServer.stop(server)
  end
  
  def send_message_stn(src, dest) do
    Station.send_message_stn(src, dest)
  end

  ## Server callbacks

  def init(:ok) do
    names = %{}
    refs  = %{}
    {:ok, {names, refs}}
  end

  def handle_call({:lookup, name}, _from, {names, _} = state) do
    {:reply, Map.fetch(names, name), state}
  end

  def handle_cast({:create, name, code}, {names, refs}) do
    if Map.has_key?(names, name) do
      {:noreply, {names, refs}}
    else
      {:ok, pid} = Station.start_link
      ref = Process.monitor(pid)
      refs = Map.put(refs, ref, name)
      names = Map.put(names, name, {code, pid})
      {:noreply, {names, refs}}
    end
  end

  def handle_info({:DOWN, ref, :process, _pid, _reason}, {names, refs}) do
    {name, refs} = Map.pop(refs, ref)
    names = Map.delete(names, name)
    {:noreply, {names, refs}}
  end

  def handle_info(_msg, state) do
    {:noreply, state}
  end


end
