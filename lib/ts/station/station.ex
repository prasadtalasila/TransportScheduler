defmodule Station do
  @moduledoc """
  Module that implements the interface of the Station.
  """

  @behaviour Station.StationBehaviour
  use GenServer
  require Station.FSM
  require Logger
  alias Station.FSM, as: FSM
  alias Util.Itinerary, as: Itinerary

  # Client-Side functions

  # Starting the GenServer

  def start_link(station_data) when is_list(station_data) do
    Logger.info(fn ->
      "Station starting for station_number=#{hd(station_data).station_number}"
    end)

    GenServer.start_link(Station, station_data)
  end

  def init(station_data = [_station_struct, _dependency]) do
    station_fsm = FSM.initialise_fsm(station_data)
    {:ok, station_fsm}
  end

  def stop(pid) do
    Logger.info(fn -> "Station stopped at pid=#{inspect(pid)}" end)
    GenServer.stop(pid, :normal)
  end

  # Getting the current schedule
  def get_timetable(pid) do
    Logger.info(fn -> "Getting the current schedule at pid=#{inspect(pid)}" end)

    GenServer.call(pid, :get_schedule)
  end

  # Updating the current state
  def update(pid, new_vars) do
    Logger.info(fn -> "Updating the current state at pid=#{inspect(pid)}" end)
    GenServer.cast(pid, {:update, new_vars})
  end

  def send_query(pid, query) do
    Logger.info(fn ->
      "Received query #{Itinerary.get_query_id(query)} at pid=#{inspect(pid)}"
    end)

    GenServer.cast(pid, {:receive, query})
  end

  def handle_call(:get_schedule, _from, station_fsm) do
    timetable = FSM.get_timetable(station_fsm)
    {:reply, timetable, station_fsm}
  end

  def handle_cast({:receive, itinerary}, station_fsm) do
    station_fsm = FSM.process_itinerary(station_fsm, itinerary)

    {:noreply, station_fsm}
  end

  def handle_cast({:update, new_vars}, station_fsm) do
    station_fsm = FSM.update(station_fsm, new_vars)
    {:noreply, station_fsm}
  end

  def handle_info(_, station_fsm) do
    {:noreply, station_fsm}
  end
end
