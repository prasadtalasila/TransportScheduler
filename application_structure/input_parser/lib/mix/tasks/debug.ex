defmodule Mix.Tasks.Debug do
  use Mix.Task
  require Logger


  def run(args) do

    Mix.Task.run "app.start"

    [tuple]=Supervisor.which_children(InputParser.Supervisor)
      pid=elem(tuple,1)

    qmap=InputParser.get_query_map(pid)

    Logger.debug("Qmap is #{inspect qmap}")

  
  end
end