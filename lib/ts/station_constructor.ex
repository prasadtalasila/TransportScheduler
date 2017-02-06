# Module to create registry process for monitoring all station processes, ie, Network Constructor NC

defmodule StationConstructor do
  use GenServer

  def add_query(server, query) do
    GenServer.cast(server, {:add_query, query})
  end

  def del_query(server, query) do
    GenServer.cast(server, {:del_query, query})
  end

  def check_active(server, query) do
    GenServer.call(server, {:check_active, query})
  end

  # Client-side NC management functions
  def start_link do
    GenServer.start_link(__MODULE__, :ok, [])
  end

  def create(server, name, code) do
    GenServer.cast(server, {:create, name, code})
  end
  
  def stop(server) do
    GenServer.stop(server, :normal)
  end

  # Client-side lookup functions

  def lookup_name(server, name) do
    GenServer.call(server, {:lookup_name, name})
  end

  def lookup_code(server, code) do
    GenServer.call(server, {:lookup_code, code})
  end

  # Client-side message-passing functions

  def send_to_src(src, dest, itinerary) do
    Station.receive_at_src(src, dest, itinerary)
  end

  def receive_from_dest(server, itinerary) do
    GenServer.call(server, {:msg_received_at_NC, itinerary})
  end

  # Server-side callback functions

  def init(:ok) do
    # new registry process for NC started
    names = %{}
    codes = %{}
    refs  = %{}
    queries=%{}
    {:ok, {names, codes, refs, queries}}
  end

  def handle_call({:lookup_name, name}, _from, {names, _, _, _} = state) do
    # station name lookup from Map in registry
    {:reply, Map.fetch(names, name), state}
  end

  def handle_call({:lookup_code, code}, _from, {_, codes, _, _} = state) do
    # station code lookup from Map in registry
    {:reply, Map.fetch(codes, code), state}
  end

  def handle_call({:msg_received_at_NC, itinerary}, _from, {names, codes, refs, queries}) do
    # feasible itineraries returned to NC are displayed
    #IO.inspect itinerary
    API.start_link
    list=API.get(List.first(itinerary))
    #list=[itinerary | list]
    if (length(list)<50) do
      list=list++[itinerary]
      API.put(List.first(itinerary), list)
    else
      queries=Map.delete(queries, List.first(itinerary))
    end
    {:reply, itinerary, {names, codes, refs, queries}}
  end

  def handle_call({:check_active, query}, _from, {_, _, _, queries}=state) do
    {:reply, Map.get(queries, query), state}
  end

  def handle_cast({:create, name, code}, {names, codes, refs, queries}=state) do
    # new station process created if not in NC registry
    if Map.has_key?(names, name) do
      {:noreply, state}
    else
      {:ok, pid} = Station.start_link
      ref = Process.monitor(pid)
      refs = Map.put(refs, ref, {name, code})
      names = Map.put(names, name, {code, pid})
      codes = Map.put(codes, code, {name, pid})
      {:noreply, {names, codes, refs, queries}}
    end
  end

  def handle_cast({:add_query, query}, {names, codes, refs, queries}) do
    queries=Map.put(queries, query, true)
    {:noreply, {names, codes, refs, queries}}
  end

  def handle_cast({:del_query, query}, {names, codes, refs, queries}) do
    queries=Map.delete(queries, query)
    {:noreply, {names, codes, refs, queries}}
  end

  def handle_info({:DOWN, ref, :process, _pid, _reason}, {names, codes, refs, queries}) do
    {name, code, refs} = Map.pop(refs, ref)
    names = Map.delete(names, name)
    codes = Map.delete(codes, code)
    {:noreply, {names, codes, refs, queries}}
  end

  def handle_info(_msg, state) do
    {:noreply, state}
  end


end
