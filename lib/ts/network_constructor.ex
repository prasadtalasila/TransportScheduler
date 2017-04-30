defmodule NetworkConstructor do
	@moduledoc """
	Module to create registry process for monitoring all station processes and
	queries using a Network Constructor. The NC process can be used to add or
	remove queries from the active query list and check if a query is active.
	It can also be used to maintain a map of station pids, station codes, and
	station city names for convenient retrieval.

	Uses GenServer.
	"""
	use GenServer, async: true

	@doc """
	Adds a query to active list maintained at NC.

	### Parameters
	nc_pid

	query - in the form of a map %{src_station, dst_station, arrival_time,
	end_time}

	conn

	### Return values
	Returns {:ok}.
	"""
	def add_query(server, query, conn) do
		GenServer.cast(server, {:add_query, query, conn})
	end

	@doc """
	Removes a query from active list maintained at NC.

	### Parameters
	nc_pid

	query - in the form of a map %{src_station, dst_station, arrival_time,
	end_time}

	### Return values
	Returns {:ok}.
	"""
	def del_query(server, query) do
		GenServer.cast(server, {:del_query, query})
	end

	@doc """
	Checks if a query is currently in active list maintained at NC.

	### Parameters
	nc_pid

	query - in the form of a map %{src_station, dst_station, arrival_time,
	end_time}

	### Return values
	Returns {:ok}.
	"""
	def check_active(server, query) do
		GenServer.call(server, {:check_active, query})
	end

	@doc """
	Returns active query list maintained at NC.

	### Parameters
	nc_pid

	### Return values
	Returns {:reply, queries, state}.

	"""
	def return_queries(server) do
		GenServer.call(server, {:return_queries})
	end

	def put_queries(server, queries) do
		GenServer.cast(server, {:put_queries, queries})
	end

	# Client-side NC management functions

	@doc """
	Starts a GenServer NetworkConstructor process linked to the current
	process.

	This is often used to start the GenServer as part of a supervision tree.

	Once the server is started, the `init/1` function of the given module
	is called with args as its arguments to initialize the server.

	### Parameters
	module

	args

	options:
	- :name - used for name registration
	- :timeout - if present, the server is allowed to spend the given
	amount of milliseconds initializing or it will be terminated and the
	start function will return {:error, :timeout}
	- :debug - if present, the corresponding function in the :sys module
	is invoked
	- :spawn_opt - if present, its value is passed as options to the
	underlying process

	### Return values
	If the server is successfully created and initialized, this function
	returns {:ok, pid}, where pid is the PID of the server. If a process with
	the specified server name already exists, this function returns {:error,
	{:already_started, pid}} with the PID of that process.

	If the `init/1` callback fails with reason, this function returns
	{:error, reason}. Otherwise, if it returns {:stop, reason} or :ignore,
	the process is terminated and this function returns {:error, reason}
	or :ignore, respectively.

	"""
	def start_link(name) do
		GenServer.start_link(__MODULE__, :ok, name: name)
	end

	@doc """
	Starts a new Station process and adds new pid to registry map using
	supervisor. Supervisor is also used to restart crashed process and
	update registry map with new pid.

	### Parameters
	nc_pid

	station_name

	station_code

	### Return values
	Returns {:ok}.
	"""
	def create(server, name, code) do
		GenServer.cast(server, {:create, name, code})
	end

	@doc """
	Stops the NC process with the given reason.

	### Parameters
	nc_pid

	### Return values
	The `terminate/2` callback of the given server will be invoked before
	exiting. This function returns :ok if the server terminates with the
	given reason; if it terminates with another reason, the call exits.
	"""
	def stop(server) do
		GenServer.stop(server, :normal)
	end

	# Client-side lookup functions

	@doc """
	Returns station pid and code from registry given the station name.

	### Parameters
	nc_pid

	station_name

	### Return values
	Returns {:reply, {code, pid}, state}.
	"""
	def lookup_name(server, name) do
		GenServer.call(server, {:lookup_name, name})
	end

	@doc """
	Returns station pid and name from registry given the station code.

	### Parameters
	nc_pid

	station_code

	### Return values
	Returns {:reply, {name, pid}, state}.
	"""
	def lookup_code(server, code) do
		GenServer.call(server, {:lookup_code, code})
	end

	# Client-side message-passing functions

	@doc """
	Sends a query encoded in itinerary from NC to the source station using
	`receive_at_src/3` of Station module. The pid of NC and source station
	must be known.

	### Parameters
	nc_pid

	src_stn_pid

	itinerary - in the form of a map %{vehicleID, src_station, dst_station,
	dept_time, arrival_time, mode_of_transport}

	### Return values
	Returns {:ok}
	"""
	def send_to_src(src, dest, itinerary) do
		Station.receive_at_src(src, dest, itinerary)
	end

	# Server-side callback functions

	def init(:ok) do
		# new registry process for NC started
		names=%{}
		codes=%{}
		refs=%{}
		queries=%{}
		{:ok, {names, codes, refs, queries}}
	end

	def handle_call({:return_queries}, _from, {_, _, _, queries}=state) do
		# return the list of active queries
		{:reply, queries, state}
	end

	def handle_call({:lookup_name, name}, _from, {names, _, _, _}=state) do
		# station name lookup from Map in registry
		{:reply, Map.fetch(names, name), state}
	end

	def handle_call({:lookup_code, code}, _from, {_, codes, _, _}=state) do
		# station code lookup from Map in registry
		{:reply, Map.fetch(codes, code), state}
	end

	def handle_call({:check_active, query}, _from, {_, _, _, queries}=state) do
		if Map.get(queries, query)===nil do
			{:reply, false, state}
		else
			{:reply, true, state}
		end
	end

	def handle_cast({:put_queries, queries}, {names, codes, refs, _}) do
		{:noreply, {names, codes, refs, queries}}
	end

	def handle_cast({:create, name, code}, {names, codes, refs, queries}=state) do
		# new station process created if not in NC registry
		if Map.has_key?(names, name) do
			{:noreply, state}
		else
			{:ok, pid}=TS.Station.Supervisor.start_station
			ref=Process.monitor(pid)
			refs=Map.put(refs, ref, {name, code})
			names=Map.put(names, name, {code, pid})
			codes=Map.put(codes, code, {name, pid})
			{:noreply, {names, codes, refs, queries}}
		end
	end

	def handle_cast({:add_query, query, conn}, {names, codes, refs, queries}) do
		queries=Map.put(queries, query, conn)
		{:noreply, {names, codes, refs, queries}}
	end

	def handle_cast({:del_query, query}, {names, codes, refs, queries}) do
		queries=Map.delete(queries, query)
		{:noreply, {names, codes, refs, queries}}
	end

	def handle_info({:DOWN, ref, :process, _pid, _reason}, {names, codes, refs, queries}) do
		{{name, code}, refs}=Map.pop(refs, ref)
		names=Map.delete(names, name)
		codes=Map.delete(codes, code)
		NetworkConstructor.create(NetworkConstructor, name, code)
		{:noreply, {names, codes, refs, queries}}
	end

	def handle_info(_msg, state) do
		{:noreply, state}
	end
end
