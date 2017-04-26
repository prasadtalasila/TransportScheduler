defmodule QC do
	@moduledoc """
	The Query Collector: this module abstracts the final query collector i.e. for concurrent functionality, a separate process collects itineraries of a given query.
	"""
	use GenServer, async: true

	## Functions (Client)

	
	@doc """
	Starts a GenServer QC process linked to the current process.   
	This is often used to start the GenServer as part of a supervision tree.   
	Once the server is started, the `init/1` function of the given module is called with args as its arguments to initialize the server.
	
	### Parameters
	module   
	args   

	### Return values
	If the server is successfully created and initialized, this function returns {:ok, pid}, where pid is the PID of the server. If a process with the specified server name already exists, this function returns {:error, {:already_started, pid}} with the PID of that process.   
	If the `init/1` callback fails with reason, this function returns {:error, reason}. Otherwise, if it returns {:stop, reason} or :ignore, the process is terminated and this function returns {:error, reason} or :ignore, respectively.

	"""
	def start_link do
		GenServer.start_link(QC, :ok)
	end

	@doc """
	Collects the list of itineraries for the query by appending given itinerary to exisiting list after checking whether query is active and limit of collected responses is not reached, using API function `add_itinerary/2`.

	### Parameters
	server
	itinerary

	### Return values
	Returns {:ok}.
	"""
	def collect(server, itinerary) do
		GenServer.cast(server, {:collect, itinerary})
	end


	@doc """
	Stops the QC process with the given reason.   

	### Parameters
	pid

	### Return values
	The `terminate/2` callback of the given server will be invoked before exiting. This function returns :ok if the server terminates with the given reason; if it terminates with another reason, the call exits.
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
