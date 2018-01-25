defmodule Station do

	@moduledoc"""
	Module that implements the interface of the Station.
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
		{:ok, station_fsm}
	end

	def handle_call(:get_vars, _from, station_fsm) do
		vars = station_fsm.data
		station_vars = Enum.at(vars, 0)
		{:reply, station_vars, station_fsm}
	end

	def handle_call(:get_state, _from, station_fsm) do
		fsm_state = StationFsm.state(station_fsm)
		{:reply, fsm_state, station_fsm}
	end

	def handle_cast({:update, new_vars}, station_fsm) do
		station_fsm = StationFsm.update(station_fsm, new_vars)
		{:noreply, station_fsm}
	end

	def handle_cast({:receive, itinerary}, station_fsm) do
		station_fsm = station_fsm |>
		StationFsm.query_input(itinerary) |>
		StationFsm.check_query_status

		station_fsm = if StationFsm.state(station_fsm) != :ready do
			StationFsm.initialize(station_fsm)
		else
			station_fsm
		end

		station_fsm = if StationFsm.state(station_fsm) != :ready do
			StationFsm.process_station_schedule(station_fsm)
		else
			station_fsm
		end

		{:noreply, station_fsm}
	end

	def send_to_station(pid, query) do
		GenServer.cast(pid, {:receive, query})
	end

end
