defmodule TS.Supervisor do
  use Supervisor

  def start_link do
    Supervisor.start_link(__MODULE__, :ok)
  end

  def init(:ok) do
    children=[
      worker(StationConstructor, [StationConstructor]),
      supervisor(TS.API.Supervisor, []),
      supervisor(TS.Station.Supervisor, [])
    ]

    supervise(children, strategy: :rest_for_one)
  end
  
end