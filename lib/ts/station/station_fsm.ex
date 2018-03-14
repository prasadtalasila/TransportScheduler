defmodule Station.Fsm do
  @moduledoc """
  Provides implementation of the core logic of a Station.
  """

  use Fsm, initial_state: :start, initial_data: []
  alias Station.Fsm

  # Function definitions
  def initialise_fsm(input = [_station_vars, _dependency]) do
    Fsm.new()
    |> Fsm.input_data(input)
  end

  def process_itinerary(station_fsm, itinerary) do
    station_fsm =
      station_fsm
      |> Fsm.query_input(itinerary)
      |> Fsm.check_query_status()

    if Fsm.state(station_fsm) != :ready do
      Fsm.initialise(station_fsm)
    else
      station_fsm
    end
  end

  def get_timetable(station_fsm) do
    station_state =
      station_fsm
      |> Fsm.data()
      |> Enum.at(0)

    station_state.schedule
  end

  # Check if the query is valid / completed / invalid
  defp query_status(station_vars, itinerary, dependency) do
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
            station_vars.station_number,
            itinerary
          ) ->
        :invalid

      true ->
        :valid
    end
  end

  # Send the new itinerary to the neighbour
  defp send_to_neighbour(conn, itinerary, dependency) do
    registry = dependency.registry
    station = dependency.station
    # get neighbour pid
    next_station_pid = registry.lookup_code(conn.dst_station)
    # Forward itinerary to next station's pid
    station.send_query(next_station_pid, itinerary)
  end

  # Initialise neighbours_fulfilment array
  defp init_neighbours(schedule, _other_means) do
    dst = schedule

    # Add neighbours from concatenated list
    Map.new(dst, fn x -> {x.dst_station, 0} end)
  end

  defp update_days_travelled(itinerary, dependency) do
    itinerary_fn = dependency.itinerary
    query = itinerary_fn.get_query(itinerary)

    if itinerary_fn.is_empty(itinerary) do
      {itinerary, query.arrival_time}
    else
      previous_link = itinerary_fn.get_last_link(itinerary)

      if previous_link.arrival_time >= 86_400 do
        day_increment = div(previous_link.arrival_time, 86_400)
        new_itinerary = itinerary_fn.increment_day(itinerary, day_increment)
        {new_itinerary, Integer.mod(previous_link.arrival_time, 86_400)}
      else
        {itinerary, previous_link.arrival_time}
      end
    end
  end

  defp process_schedule(itinerary_iterator, dependency) do
    itinerary_fn = dependency.itinerary

    case itinerary_fn.next_itinerary(itinerary_iterator) do
      {new_iterator, conn, itinerary} ->
        send_to_neighbour(conn, itinerary, dependency)
        process_schedule(new_iterator, dependency)

      _ ->
        nil
    end
  end

  # State definitions

  # start state
  defstate start do
    # On getting the data input, go to ready state
    defevent input_data(station_data = [_station_vars, _dependency]) do
      next_state(:ready, station_data)
    end
  end

  # ready state
  defstate ready do
    # When local variables of the station are updated
    defevent update(new_vars), data: [_station_vars, dependency] do
      # Replace each entry in the struct original_vars with each entry
      # in new_vars

      schedule = Enum.sort(new_vars.schedule, &(&1.dept_time <= &2.dept_time))

      new_station_vars = %Util.StationStruct{
        loc_vars: new_vars.loc_vars,
        schedule: schedule,
        other_means: new_vars.other_means,
        station_number: new_vars.station_number,
        station_name: new_vars.station_name,
        pid: new_vars.pid,
        congestion_low: new_vars.congestion_low,
        congestion_high: new_vars.congestion_high,
        choose_fn: new_vars.choose_fn
      }

      # Return to ready state with new variables
      vars = [new_station_vars, dependency]
      next_state(:ready, vars)
    end

    # When an itinerary is passed to the station
    defevent query_input(itinerary), data: vars = [_station_vars, _dependency]
    do
      # Give itinerary as part of query
      vars = [itinerary | vars]
      next_state(:query_rcvd, vars)
    end
  end

  # query_rcvd state
  defstate query_rcvd do
    defevent check_query_status,
      data: vars = [itinerary, station_vars, dependency] do
      q_stat = query_status(station_vars, itinerary, dependency)

      case q_stat do
        :invalid ->
          # If invalid query, remove itinerary
          new_vars = List.delete_at(vars, 0)
          next_state(:ready, new_vars)

        :collect ->
          # If completed query, send to
          dependency.collector.collect(itinerary)
          new_vars = List.delete_at(vars, 0)
          next_state(:ready, new_vars)

        :valid ->
          # If valid query, compute
          next_state(:query_init, vars)
      end
    end
  end

  # query_init state
  defstate query_init do
    defevent initialise, data: vars = [itinerary, station_vars, dependency] do
      itinerary_fn = dependency.itinerary

      # Find all neighbors
      neighbour_map =
        init_neighbours(station_vars.schedule, station_vars.other_means)

      # Replace neighbours keyword-list in struct
      # new_station_vars = %{station_vars | neighbours: nbrs}
      {itinerary, arrival_time} = update_days_travelled(itinerary, dependency)

      vars = [itinerary | List.delete_at(vars, 0)]

      # Get iterator to valid itineraries.
      itinerary_iterator =
        itinerary_fn.valid_itinerary_iterator(
          neighbour_map,
          station_vars.schedule,
          arrival_time,
          vars
        )

      process_schedule(itinerary_iterator, dependency)
      next_state(:ready, [station_vars, dependency])
    end
  end
end
