defmodule Station do
  @moduledoc """
  Module that implements the interface of the Station.
  """

  @behaviour Station.StationBehaviour
  use GenServer
  require Station.Fsm
  alias Station.Fsm

  # Client-Side functions

  # Starting the GenServer

  def start_link(station_data) when is_list(station_data) do
    GenServer.start_link(Station, station_data)
  end

  def init(station_data) do
    station_fsm = Fsm.initialise_fsm(station_data)
    {:ok, station_fsm}
  end

  def stop(pid) do
    GenServer.stop(pid, :normal)
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
    timetable = Fsm.get_timetable(station_fsm)
    {:reply, timetable, station_fsm}
  end

  def handle_cast({:update, new_vars}, station_fsm) do
    station_fsm = Fsm.update(station_fsm, new_vars)
    {:noreply, station_fsm}
  end

  def handle_cast({:receive, itinerary}, station_fsm) do
    station_fsm = Fsm.process_itinerary(station_fsm, itinerary)

    {:noreply, station_fsm}
  end

  def handle_info(_, station_fsm) do
    {:noreply, station_fsm}
  end
end
