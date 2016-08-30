# Module to pull local variable data in date,time=>locvars map format

defmodule LocVarMap do
  use GenServer

  # Client

  def start_link(default) do
    GenServer.start_link(__MODULE__, default)
  end

  def set_data(pid, key, value) do
    GenServer.cast(pid, {:put, {key, value}})
  end

  def get_data(pid, key) do
    GenServer.call(pid, {:fetch, key})
  end

  def init do
    locvarmap=%{
    	{{2016, 8, 14}, {8, 00}}=>%{:delay => 0.38, :congestion => "high", :disturbance => "no"},
      {{2016, 8, 14}, {10, 38}}=>%{:delay => 0.38, :congestion => "none", :disturbance => "yes"}
      }
    start_link(locvarmap)
  end

  # Server (callbacks)

  def handle_call({:fetch, key}, _from, loc_var_map) do
    {:reply, Map.fetch!(loc_var_map, key), loc_var_map}
  end

  def handle_call(request, from, state) do
    # Call the default implementation from GenServer
    super(request, from, state)
  end

  def handle_cast({:put, {key, value}}, loc_var_map) do
    {:noreply, Map.put(loc_var_map, key, value)}
  end

  def handle_cast(request, state) do
    super(request, state)
  end
end

