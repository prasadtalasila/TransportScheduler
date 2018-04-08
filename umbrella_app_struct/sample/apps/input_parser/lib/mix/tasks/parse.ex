defmodule Mix.Tasks.Parse do
  use Mix.Task
  require Logger


  def run(args) do

    Mix.Task.run "app.start"

    [tuple]=Supervisor.which_children(InputParser.Supervisor)
      pid=elem(tuple,1)

    qmap=InputParser.get_query_map(pid)

    IO.puts("Qmap is #{inspect qmap}")

  
  end
end