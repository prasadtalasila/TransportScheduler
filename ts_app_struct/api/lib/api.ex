defmodule API do
  @moduledoc """
  Dummy api server.
  """
  use GenServer

    def start_link(_) do

      GenServer.start_link(__MODULE__, :ok)

    end

    def init(:ok) do

      list = []
      IO.puts"API Initialised.(lib/api.ex)"
      {:ok, list}

    end

    def handle_call(:dummy_call, _from, list) do

      {:reply, list, list}

    end

end
