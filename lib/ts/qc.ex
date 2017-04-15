defmodule QC do
	@moduledoc """
	The Query Collector: this module abstracts the final query collector i.e.
	for concurrent functionality, a separate process collects itineraries of a
	given query.
	"""
	use GenServer, async: true

	## Functions (Client)

	@doc """
	Start new UQC process
	"""
	def start_link do
		GenServer.start_link(QC, :ok)
	end

	@doc """
	Add itinerary to list of itineraries
	"""
	def collect(server, itinerary) do
		GenServer.cast(server, {:collect, itinerary})
	end

	@doc """
	Stop process
	"""
	def stop(server) do
		GenServer.stop(server)
	end

	## Callbacks (Server)

	def init(:ok) do
		itineraries=[]
		{:ok, {itineraries}}
	end

	def handle_cast({:collect, itinerary}, {itineraries}) do
		#itineraries=itineraries++[itinerary]
		API.add_itinerary(StationConstructor.return_queries(StationConstructor),
			itinerary)
		{:noreply, {itineraries}}
	end

	def terminate(_, {_}) do
		:ok
	end

end
