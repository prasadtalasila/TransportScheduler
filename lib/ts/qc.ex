defmodule QC do
	@moduledoc """
	The Query Collector: this module abstracts the final query collector i.e.
	for concurrent functionality, a separate process collects itineraries of a
	given query.
	"""
	use GenServer, async: true

	## Functions (Client)

	@doc """
	Starts a new GenServer instance (of UQC module).
	"""
	def start_link do
		GenServer.start_link(QC, :ok)
	end

	@doc """
	Function called by client to add itinerary to list of itineraries.
	"""
	def collect(server, itinerary) do
		GenServer.cast(server, {:collect, itinerary})
	end

	@doc """
	Stops the given process
	"""
	def stop(server) do
		GenServer.stop(server)
	end

	## Callbacks (Server)

	@doc """
	Initialises an empty list as a part of the state.
	"""
	def init(:ok) do
		itineraries=[]
		{:ok, {itineraries}}
	end

	@doc """
	Adds an itinerary to the list of itineraries.
	"""
	def handle_cast({:collect, itinerary}, {itineraries}) do
		#itineraries=itineraries++[itinerary]
		API.add_itinerary(StationConstructor.return_queries(StationConstructor),
			itinerary)
		{:noreply, {itineraries}}
	end

	@doc """
	Performs cleanup when stop() is called.
	"""
	def terminate(reason, {itineraries}) do
		itineraries=[]
		:ok
	end

end
