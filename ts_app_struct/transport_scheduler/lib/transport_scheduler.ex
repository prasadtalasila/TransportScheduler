defmodule TransportScheduler do
  @moduledoc """
  Dummy transport scheduler server.
  """
  use GenServer

  def start_link(_) do

    GenServer.start_link(__MODULE__, :ok)

  end

  def init(:ok) do

    list = []
    IO.puts"Transport Scheduler Initialised.(lib/transport_scheduler.ex)"
    {:ok, list}

  end

  def handle_call(:dummy_call, _from, list) do

    {:reply, list, list}

  end

end
