defmodule Station do

	@moduledoc"""
	Module that implements the interface of the station module
	"""

	@behaviour StationBehaviour
	use GenServer


	# Client-Side functions

	def start_link([station_vars, registry, qc]) do
		GenServer.start_link(__MODULE__, [station_vars, registry, qc])
	end

	def get_vars(stn) do
		GenServer.call(stn, :get_vars)
 	end

	def get_state(stn) do
		GenServer.call(stn, :get_state)
	end

	def update(stn, new_vars) do
		GenServer.cast(stn, {:update, new_vars}) 
	end

	def receive_at_src(src, itinerary) do
		GenServer.cast(src, {:receive_at_src, src, itinerary})
	end

	def send_to_stn(src, dst, itinerary) do
		GenServer.cast(dst, {:send_to_stn, src, itinerary})
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
		fsm_state = station_fsm.state
		{:reply, fsm_state, {station_fsm}}

	end

	def handle_cast({:update, stn, new_vars}, {station_fsm}) do
		# StationFsm.transition(station_fsm, :update, [new_vars])
		# {:noreply, {station_fsm}}
	end

	def handle_cast({:receive_at_src, src, itinerary}, {station_fsm}) do
		# StationFsm.transition(station_fsm, :query_input, [itinerary]) |>
		# StationFsm.transition(:check_query_status, [])

		# fsm_state = StationFsm.state(station_fsm)
		# case fsm_state do
		# 	:query_init ->
		# 		StationFsm.transition(station_fsm, :initialize, [])
		# 		# check-stop - compute-connections loop
		# 	_ ->
		# end 
		# {:noreply, {station_fsm}}
	end

	def handle_cast({:send_to_stn, src, itinerary}, {station_fsm}) do
		# StationFsm.transition(station_fsm, :send_to_stn, [itinerary])
	end

end
