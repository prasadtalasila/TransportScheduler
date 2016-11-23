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
  def lookup_name(server, name) do
    GenServer.call(server, {:lookup_name, name})
  end

  def lookup_code(server, code) do
    GenServer.call(server, {:lookup_code, code})
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

  @doc """
  Messages.
  """
  def send_to_src(src, dest, itinerary) do
    Station.receive_at_src(src, dest, itinerary)
  end

  def receive_from_dest(server, itinerary) do
    GenServer.call(server, {:msg_received_at_NC, itinerary})
  end

  ## Server callbacks

  def init(:ok) do
    names = %{}
    codes = %{}
    refs  = %{}
    {:ok, {names, codes, refs}}
  end

  def handle_call({:lookup_name, name}, _from, {names, _, _} = state) do
    {:reply, Map.fetch(names, name), state}
  end

  def handle_call({:lookup_code, code}, _from, {_, codes, _} = state) do
    {:reply, Map.fetch(codes, code), state}
  end

  def handle_call({:msg_received_at_NC, itinerary}, _from, {_, _, _} = state) do
    #IO.puts "in NC"
    IO.inspect itinerary
    API.start_link
    API.put("itinerary", itinerary)
    {:reply, itinerary, state}
  end

  def handle_cast({:create, name, code}, {names, codes, refs}) do
    if Map.has_key?(names, name) do
      {:noreply, {names, codes, refs}}
    else
      {:ok, pid} = Station.start_link
      ref = Process.monitor(pid)
      refs = Map.put(refs, ref, {name, code})
      names = Map.put(names, name, {code, pid})
      codes = Map.put(codes, code, {name, pid})
      {:noreply, {names, codes, refs}}
    end
  end

  def handle_info({:DOWN, ref, :process, _pid, _reason}, {names, codes, refs}) do
    {name, code, refs} = Map.pop(refs, ref)
    names = Map.delete(names, name)
    codes = Map.delete(codes, code)
    {:noreply, {names, codes, refs}}
  end

  def handle_info(_msg, state) do
    {:noreply, state}
  end


end
