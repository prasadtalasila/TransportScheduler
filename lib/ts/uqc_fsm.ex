defmodule UQCFSM do
	@moduledoc """
	Module to filter results of the search query in UQC based on user
	preferences
	"""
	use GenStateMachine

	# Client

	@doc """
	Start new FSM process
	"""
	def start_link do
		GenStateMachine.start_link(UQCFSM, {:raw, nil})
	end

	@doc """
	Update state of FSM
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
