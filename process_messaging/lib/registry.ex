defmodule Registry do
  use GenServer, async: true

  def start_link do
    GenServer.start_link(__MODULE__, :ok)
  end

  def init(:ok) do
    record = %{}
    count = 0
    counter = 0
    {:ok, {record, count, counter} }
  end

  def addProcess(server, pid) do
    GenServer.cast(server,{:put, pid})
  end

  def handle_cast({:put, pid}, {record, count, counter}) do
    Map.put(record, pid, True)
    {:noreply, {record, count, counter}}
  end

  def start_timer(server) do
    GenServer.cast(server,:start_timer)
  end

  def handle_cast(:start_timer, {record, count, counter}) do
    counter = 0
    Process.send_after(self(), :stop_benchmark, 30_000)
    {:noreply, {record, count, counter}}
  end

  def handle_info(:stop_benchmark, {record, count, counter}) do
    count = counter
    {:noreply, {record, count, counter}}
  end

  def getCount(server) do
    GenServer.call(server, {:get_count})
  end

  def handle_call( {:get_count}, _from, { record , count, counter}) do
    {:reply, count, { record , count, counter}}
  end

  def lookup(server, key) do
    GenServer.call(server, {:query, key})
  end

  def handle_call({:query, key}, _from, { record , count, counter}) do
    counter = counter + 1
    {:reply, key , { record , count, counter}}
  end

  def stop(server) do
    GenServer.call(server,:stop_processes)
    GenServer.stop(server)
  end

  def handle_call(:stop_processes, _from, { record , count, counter}) do
    for {pid, _} <- record do
      Process.exit(pid, :normal)
    end
    {:reply, :done, { record , count, counter}}
  end
end
