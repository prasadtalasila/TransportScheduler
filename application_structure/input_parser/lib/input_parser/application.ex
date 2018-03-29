defmodule InputParser.Application do


	use Application

	def start(_type, _args) do

	children = [
	  { InputParser,[]}
	]

	IO.puts("Starting application in InputParser.Application(lib/input_parser/application.ex)")


	opts = [strategy: :one_for_one, name: InputParser.Supervisor]
	Supervisor.start_link(children, opts)   

	end


end