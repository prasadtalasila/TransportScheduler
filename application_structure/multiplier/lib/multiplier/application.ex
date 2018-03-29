defmodule Multiplier.Application do
	
	use Application

	def start(_type, _args) do

	children = [
	  { Multiplier,[]}
	]

	IO.puts("Starting application in Multiplier.Application(lib/multiplier/application.ex)")


	opts = [strategy: :one_for_one, name: Multiplier.Supervisor]
	Supervisor.start_link(children, opts)   

	end
end