defmodule API.Application do
  
  @moduledoc """
  Dummy API application callback module.
  """

  use Application

  def start(_type, _args) do
    
    children = [
       {API,[]},
    ]
  
    IO.puts"Starting API application.(lib/api/application.ex)"

  opts = [strategy: :one_for_one, name: API.Supervisor]
  Supervisor.start_link(children, opts)

  end

end
