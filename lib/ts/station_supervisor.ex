defmodule TS.Station.Supervisor do
	@moduledoc """
	.
	"""
	use Supervisor

	@name TS.Station.Supervisor

	@doc """
	Start supervisor process
	"""
	def start_link do
		Supervisor.start_link(__MODULE__, :ok, name: @name)
	end

	@doc """
	Start child station process
	"""
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
