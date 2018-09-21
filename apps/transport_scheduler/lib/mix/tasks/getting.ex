defmodule Mix.Tasks.Getting do
  use Mix.Task

  def run(args) do

 
  Mix.Task.run "app.start"

  [tuple]=Supervisor.which_children(TransportScheduler.Supervisor)
   pid=elem(tuple,1)


  qmap=Multiplier.write_products(pid)

  
  end
end