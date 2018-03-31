defmodule TransportScheduler.Application do
  @moduledoc """
  Dummy transport scheduler application callback module.
  """

  use Application

  def start(_type, _args) do
    
    children = [
     {TransportScheduler,[]}
    ]

    IO.puts"Starting TransportScheduler application.(lib/transport_scheduler/application.ex)"

    opts = [strategy: :one_for_one, name: TransportScheduler.Supervisor]
    Supervisor.start_link(children, opts)

  end

end
