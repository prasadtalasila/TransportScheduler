defmodule TS.API.Supervisor do
	@moduledoc """
	Module to start supervisor for API process
	"""
	use Supervisor
	@name TS.API.Supervisor

	@doc """
	Start supervisor process
	"""
	def start_link do
		Supervisor.start_link(__MODULE__, :ok, name: @name)
	end

	@doc """
	Start child API process
	"""
	def start_api do
		Supervisor.start_child(@name, [])
	end

	def init(:ok) do
		children=[
			worker(API, [], restart: :temporary)
		]
		supervise(children, strategy: :simple_one_for_one)
	end
end
