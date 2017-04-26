defmodule UQCFSM do
	@moduledoc """
	Module to filter results of the search query in UQC based on user
	preferences.
	"""
	use GenStateMachine

	# Client

	@doc """
	Starts a GenStateMachine UQCFSM process linked to the current process.   
	This is often used to start the GenStateMachine as part of a supervision tree.   
	Once the server is started, the `init/1' function of the given module is called with args as its arguments to initialize the server.   
	
	### Parameters
	module   
	args   
	
	### Return values
	If the server is successfully created and initialized, this function returns {:ok, pid}, where pid is the PID of the server. If a process with the specified server name already exists, this function returns {:error, {:already_started, pid}} with the PID of that process.   
	If the `init/1' callback fails with reason, this function returns {:error, reason}. Otherwise, if it returns {:stop, reason} or :ignore, the process is terminated and this function returns {:error, reason} or :ignore, respectively.
	"""
	def start_link do
		GenStateMachine.start_link(UQCFSM, {:raw, nil})
	end

	@doc """
	Update the state of the UQC FSM.

	### Parameters
	pid   

	### Return values
	Returns {:next_state, next_state, nil}.
	"""
	def update(server, _) do
		GenStateMachine.cast(server, {:update})
	end

	# Server
	def handle_event(:cast, {:update, _}, state, _) do
		case state do
			:raw->
	{:next_state, :mode_transport, nil}
			:mode_transport->
	# Filter based on mode of transport
	{:next_state, :cost, nil}
			:cost->
	# Put only cheap modes of transport
	{:next_state, :exit, nil}
			_->
	{:next_state, :exit, nil}
		end
	end

end
