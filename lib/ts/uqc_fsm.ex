# Module to filter results of the search query in UQC based on user preferences

defmodule UQCFSM do
	use GenStateMachine

	# Client

	def start_link do
		GenStateMachine.start_link(UQCFSM, {:raw, nil})
	end

	def update(server, itineraries) do
		GenStateMachine.cast(server, {:update})
	end

	# Server
	def handle_event(:cast, {:update, it}, state, _) do
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