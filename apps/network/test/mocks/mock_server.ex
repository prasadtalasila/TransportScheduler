defmodule MockServer do
  @moduledoc """
  Empty GenServer implementation for testing.
  """
  use GenServer, async: true

  def start_link do
    GenServer.start_link(__MODULE__, :ok)
  end

  def init(:ok) do
    {:ok, nil}
  end

  def stop(pid) do
    GenServer.stop(pid, :normal)
  end
end
