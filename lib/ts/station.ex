defmodule Station do

	@moduledoc"""
	Module that implements the interface of the station module
	"""

	@behaviour StationBehaviour
	use GenServer


	# Client-Side functions

	# Starting the GenServer

	def start_link([station_vars, registry, qc]) do
		GenServer.start_link(Station, [station_vars, registry, qc])
	end

	# Getting the local variables

	def get_vars(stn) do
		GenServer.call(stn, :get_vars)
 	end

 	# Getting the current state

	def get_state(stn) do
		GenServer.call(stn, :get_state)
	end

	# Updating the current state

	def update(stn, new_vars) do
		GenServer.cast(stn, {:update, new_vars}) 
	end

	# Callbacks

	def init([station_vars, registry, qc]) do
		station_fsm = StationFsm.new |>
		StationFsm.input_data(station_vars, registry, qc)
		{:ok, {station_fsm}}
	end

	def handle_call(:get_vars, _from, {station_fsm}) do
		vars = station_fsm.data
		station_vars = Enum.at(vars, 0)
		{:reply, station_vars, {station_fsm}}
	end

	def handle_call(:get_state, _from, {station_fsm}) do
		fsm_state = StationFsm.state(station_fsm)
		{:reply, fsm_state, {station_fsm}}
	end

	def handle_cast({:update, new_vars}, {station_fsm}) do
		station_fsm = StationFsm.update(station_fsm, new_vars)		
		{:noreply, {station_fsm}}
	end

end
