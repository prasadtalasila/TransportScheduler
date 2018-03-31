defmodule InputParser.Application do

  @moduledoc """
  Dummy input parser application callback module.
  """

  use Application

  def start(_type, _args) do
    
    children = [
      {InputParser, []}
    ]

    IO.puts"Starting input parser application.(lib/input_parser/application.ex)"
    
    opts = [strategy: :one_for_one, name: InputParser.Supervisor]

    Supervisor.start_link(children, opts)

  end

end
