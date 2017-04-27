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
	def update(_server, itinerary, pref_transport) do
		find_transport(itinerary, pref_transport)
		#GenStateMachine.cast(server, {:update})
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

	@doc """
	Checks if a particular itinerary has only flight as a mode of transport
	"""
	def check_bus([head|tail]) do
		case check_trans(head) do
			"bus"->check_bus(tail)
			"Other Means"->check_bus(tail)
			:blank->check_bus(tail)
			_->:false
		end
	end

	#Base case
	def check_bus([]) do
		:true
	end

	@doc """
	#Check if a particular itinerary has only flight as a mode of transport
	"""
	def check_flight([head|tail]) do
		case check_trans(head) do
			"flight"->check_flight(tail)
			"Other Means"->check_flight(tail)
			:blank->check_flight(tail)
			_->:false
		end
	end

	#Base case
	def check_flight([]) do
		:true
	end

	@doc """
	#Check if a particular itinerary has only train as a mode of transport
	"""
	def check_train([head|tail]) do
		case check_trans(head) do
			"train"->check_train(tail)
			"Other Means"->check_train(tail)
			:blank->check_train(tail)
			_->:false
		end
	end

	#Base case
	def check_train([]) do
		:true
	end

	#Checking map elements for mode of transport
	#For header queries
	defp check_trans(%{src_station: _, dst_station: _, day: _, arrival_time: _}) do
		:blank
	end

	#For other elements
	defp check_trans(%{vehicleID: _, src_station: _, mode_of_transport: mod, dst_station: _, dept_time: _, arrival_time: _}) do
		mod
	end

	@doc """
	Check list if preferred mode of transport is bus 
	"""
	def update_bus([head|tail]) do
		if check_bus(head)==:true do
			print_pref(:ok, head)
		end
			update_bus(tail)
	end

	#Base case
	def update_bus([]) do
		:ok
	end

	@doc """
	Checks list if preferred mode of transport is flight
	"""
	def update_flight([head|tail]) do
		if check_flight(head)==:true do
			print_pref(:ok, head)
		end
			update_flight(tail)
	end

	#Base case
	def update_flight([]) do
		:ok
	end

	@doc """
	Checks list if preferred mode of transport is train
	"""
	def update_train([head|tail]) do
		if check_train(head)==:true do
			print_pref(:ok, head)
		end
			update_train(tail)
	end

	#Base case
	def update_train([]) do
		:ok
	end

	@doc """
	Takes in the list of itineraries and preference of the user
	"""
	def find_transport(itinerary, preference) when is_list(itinerary) do
		case preference do
		:bus->update_bus(itinerary)
		:flight->update_flight(itinerary)
		:train->update_train(itinerary)
		_->IO.puts "Given transport not available."
		end
	end

	@doc """
	Printing the required lists
	"""
	#If empty list is returned
	def print_pref([]) do
		:empty
	end

	#If correct list is encountered
	def print_pref(:ok, pref) when is_list(pref) do
		#IO.inspect pref
	end

end
