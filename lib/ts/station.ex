defmodule Station do

	@moduledoc"""
	Module that implements the interface of the Station.
	"""

	@behaviour TS.StationBehaviour
	use GenServer
	require StationFsm

	# Client-Side functions

	# Starting the GenServer

	def start_link([station_vars, registry, qc]) do
		GenServer.start_link(Station, [station_vars, registry, qc])
	end

	def init([station_vars, registry, qc]) do
		station_fsm = StationFsm.new |>
		StationFsm.input_data(station_vars, registry, qc)
		{:ok, station_fsm}
	end

	def stop(pid) do
		GenServer.stop(pid)
	end

 	# Getting the current schedule

	def get_timetable(pid) do
		GenServer.call(pid, :get_schedule)
	end

	# Updating the current state

	def update(pid, new_vars) do
		GenServer.cast(pid, {:update, new_vars})
	end

	def send_query(pid, query) do
		GenServer.cast(pid, {:receive, query})
	end

	# Callbacks

	def handle_call(:get_schedule, _from, station_fsm) do
		timetable = StationFsm.get_timetable(station_fsm)
		{:reply, timetable, station_fsm}
	end

	def handle_cast({:update, new_vars}, station_fsm) do
		station_fsm = StationFsm.update(station_fsm, new_vars)
		{:noreply, station_fsm}
	end

	def handle_cast({:receive, itinerary}, station_fsm) do
		station_fsm = StationFsm.process_itinerary(station_fsm, itinerary)

		{:noreply, station_fsm}
	end

	def handle_info(_ , station_fsm) do
		{:noreply, station_fsm}
	end

end
