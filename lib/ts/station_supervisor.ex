defmodule TS.Station.Supervisor do
	@moduledoc """
	.
	"""
	use Supervisor

	@name TS.Station.Supervisor

	def start_link do
		Supervisor.start_link(__MODULE__, :ok, name: @name)
	end

	def start_station do
		Supervisor.start_child(@name, [])
	end

	def init(:ok) do
		children=[
			worker(Station, [], restart: :temporary)
		]
		supervise(children, strategy: :simple_one_for_one)
	end

end
