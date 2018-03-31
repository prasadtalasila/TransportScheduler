defmodule NetworkConstructor.Application do
  
  @moduledoc """
  Dummy network constructor application callback module.
  """

  use Application

  def start(_type, _args) do
    
    children = [
       {NetworkConstructor,[]},
    ]
	
    IO.puts"Starting network constructor application.(lib/network_constructor/application.ex)"

	opts = [strategy: :one_for_one, name: NetworkConstructor.Supervisor]
    Supervisor.start_link(children, opts)

  end

end
