defmodule Station.FSM do
  @moduledoc """
  Provides implementation of the core logic of a Station.
  """

  use Fsm, initial_state: :start, initial_data: []
  @behaviour Station.FSMBehaviour

  # Module interface definition
  def initialise_fsm(input = [_station_struct, _dependency]) do
    new()
    |> input_data(input)
  end

  def update_station(station_fsm, new_station_struct) do
    station_fsm
    |> update(new_station_struct)
  end

  def process_itinerary(station_fsm, itinerary) do
    station_fsm =
      station_fsm
      |> query_input(itinerary)
      |> check_query_status()

    if state(station_fsm) != :ready do
      initialise(station_fsm)
    else
      station_fsm
    end
  end

  def get_timetable(station_fsm) do
    station_state =
      station_fsm
      |> data()
      |> Enum.at(0)

    station_state.schedule
  end

  # State definitions

  # start state
  defstate start do
    # On getting the data input, go to ready state
    defevent input_data(station_data = [_station_struct, _dependency]) do
      next_state(:ready, station_data)
    end
  end

  # ready state
  defstate ready do
    # When local variables of the station are updated
    defevent update(new_station_struct), data: [_station_struct, dependency] do
      schedule =
        Enum.sort(
          new_station_struct.schedule,
          &(&1.dept_time <= &2.dept_time)
        )

      new_station_struct = %Util.StationStruct{
        loc_vars: new_station_struct.loc_vars,
        schedule: schedule,
        other_means: new_station_struct.other_means,
        station_number: new_station_struct.station_number,
        station_name: new_station_struct.station_name,
        pid: new_station_struct.pid,
        congestion_low: new_station_struct.congestion_low,
        congestion_high: new_station_struct.congestion_high,
        choose_fn: new_station_struct.choose_fn
      }

      # Return to ready state with new variables
      station_data = [new_station_struct, dependency]
      next_state(:ready, station_data)
    end

    # When an itinerary is passed to the station
    defevent query_input(itinerary),
      data: station_data = [_station_struct, _dependency] do
      # Give itinerary as part of query
      station_data = [itinerary | station_data]
      next_state(:query_rcvd, station_data)
    end
  end

  # query_rcvd state
  defstate query_rcvd do
    defevent check_query_status,
      data: station_data = [itinerary, station_struct, dependency] do
      q_stat = _query_status(station_struct, itinerary, dependency)

      case q_stat do
        :invalid ->
          # If invalid query, remove itinerary
          new_station_data = List.delete_at(station_data, 0)
          next_state(:ready, new_station_data)

        :collect ->
          # If completed query, send to
          dependency.collector.collect(itinerary)
          new_station_data = List.delete_at(station_data, 0)
          next_state(:ready, new_station_data)

        :valid ->
          # If valid query, compute
          next_state(:process_query, station_data)
      end
    end
  end

  # process_query state
  defstate process_query do
    defevent initialise,
      data: station_data = [itinerary, station_struct, dependency] do
      itinerary_fn = dependency.itinerary

      # Find all neighbors
      neighbour_map =
        _init_neighbours(
          station_struct.schedule,
          station_struct.other_means
        )

      # Replace neighbours keyword-list in struct
      # new_station_struct = %{station_struct | neighbours: nbrs}
      {itinerary, arrival_time} = itinerary_fn.update_days_travelled(itinerary)

      station_data = [itinerary | List.delete_at(station_data, 0)]

      # Get iterator to valid itineraries.
      itinerary_iterator =
        itinerary_fn.valid_itinerary_iterator(
          {neighbour_map, station_struct.schedule, arrival_time},
          station_data
        )

      _process_schedule(itinerary_iterator, dependency)
      next_state(:ready, [station_struct, dependency])
    end
  end

  # Helper Function definitions

  # Check if the query is valid / completed / invalid
  defp _query_status(station_struct, itinerary, dependency) do
    # returns true if query is active, false otherwise
    itinerary_fn = dependency.itinerary
    registry = dependency.registry

    active = registry.check_active(itinerary_fn.get_query_id(itinerary))

    cond do
      active && itinerary_fn.is_empty(itinerary) ->
        :valid

      active && itinerary_fn.is_terminal(itinerary) ->
        :collect

      !active ||
          !itinerary_fn.is_valid_destination(
            station_struct.station_number,
            itinerary
          ) ->
        :invalid

      true ->
        :valid
    end
  end

  # Send the new itinerary to the neighbour
  defp _send_to_neighbour(conn, itinerary, dependency) do
    registry = dependency.registry
    station = dependency.station
    # get neighbour pid
    next_station_pid = registry.lookup_code(conn.dst_station)
    # Forward itinerary to next station's pid
    station.send_query(next_station_pid, itinerary)
  end

  # Initialise neighbours_fulfilment array
  defp _init_neighbours(schedule, _other_means) do
    dst = schedule

    # Add neighbours from concatenated list
    Map.new(dst, fn x -> {x.dst_station, 0} end)
  end

  defp _process_schedule(itinerary_iterator, dependency) do
    itinerary_fn = dependency.itinerary

    case itinerary_fn.next_itinerary(itinerary_iterator) do
      {new_iterator, conn, itinerary} ->
        _send_to_neighbour(conn, itinerary, dependency)
        _process_schedule(new_iterator, dependency)

      _ ->
        nil
    end
  end
end
