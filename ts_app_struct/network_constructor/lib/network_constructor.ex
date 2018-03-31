defmodule NetworkConstructor do
  @moduledoc """
  Dummy network constructor server.
  """
  use GenServer

    def start_link(_) do

      GenServer.start_link(__MODULE__, :ok)

    end

    def init(:ok) do

      list=[]
      IO.puts"Network constructor Initialised.(lib/network_constructor.ex)"
      {:ok,list}

    end

    def handle_call(:dummy_call, _from,list) do

      {:reply,list,list}

    end

end
