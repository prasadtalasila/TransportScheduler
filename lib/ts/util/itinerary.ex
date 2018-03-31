defmodule Util.Itinerary do
  @moduledoc """
  Defines the operations that can be performed on the itinerary container of the
   format {query, route, preferences}.
  """

  @behaviour Util.ItineraryBehaviour

  require Logger
  # generates itinerary in the format {query, route, preference}
  def new(query, route, preference), do: {query, route, preference}

  def new(query, preference), do: {query, [], preference}

  # Returns true if the itinerary route is empty.
  def is_empty(itinerary) do
    route = get_route(itinerary)

    if route == [] do
      true
    else
      false
    end
  end

  # Updates the number of days travelled in an itinerary
  # and also returns the arrival time of the last link
  def update_days_travelled(itinerary) do
    query = get_query(itinerary)

    itinerary_arr_time =
      if is_empty(itinerary) do
        {itinerary, query.arrival_time}
      else
        previous_link = get_last_link(itinerary)

        if previous_link.arrival_time >= 86_400 do
          day_increment = div(previous_link.arrival_time, 86_400)
          new_itinerary = increment_day(itinerary, day_increment)
          {new_itinerary, Integer.mod(previous_link.arrival_time, 86_400)}
        else
          {itinerary, previous_link.arrival_time}
        end
      end

    Logger.debug(fn ->
      "itinerary_arr_time = #{inspect(itinerary_arr_time)}"
    end)

    itinerary_arr_time
  end

  # Check if connection is feasible on second pass over the schedule
  defp _feasibility_check(conn, itinerary, _arrival_time, :second_pass) do
    query = get_query(itinerary)
    preference = get_preference(itinerary)

    result_feasibility_check =
      if query.end_time >= preference.day * 86_400 + conn.arrival_time do
        true
      else
        false
      end

    Logger.debug(fn ->
      "result_feasibility_check = #{result_feasibility_check}"
    end)

    result_feasibility_check
  end

  # Check if connection is feasible
  defp _feasibility_check(conn, itinerary, arrival_time, :first_pass) do
    query = get_query(itinerary)
    preference = get_preference(itinerary)

    result_feasibility_check =
      if conn.dept_time > arrival_time &&
           preference.day * 86_400 + conn.arrival_time <= query.end_time do
        true
      else
        false
      end

    Logger.debug(fn ->
      "result_feasibility_check = #{result_feasibility_check}"
    end)

    result_feasibility_check
  end

  # Iterates over the the station schedule to generate new itineraries to be
  # sent to neighbouring stations.
  def next_itinerary(
        vars = [
          {neighbour_map, schedule, _arrival_time, _flag, _pass}
          | _vars_tail
        ]
      ) do
    # Find out if stop or not
    should_stop = stop_fn(neighbour_map, schedule)
    Logger.debug(fn -> "should_stop = #{inspect(should_stop)}" end)

    result_find_valid_connection =
      if should_stop == false && vars != nil do
        _find_valid_connection(vars)
      else
        nil
      end

    Logger.debug(fn ->
      "The value from _find_valid_connection = #{
        inspect(result_find_valid_connection)
      }"
    end)

    result_find_valid_connection
  end

  # Iterate over the schedule to find a valid connection.
  defp _find_valid_connection([
         {_neighbour_map, [flag | _schedule_tail], _arrival_time, flag,
          :second_pass},
         _itinerary,
         _station_struct,
         _dependency
       ]) do
    nil
  end

  defp _find_valid_connection([
         {neighbour_map, [conn | schedule_tail], arrival_time, flag, pass},
         itinerary,
         station_struct,
         dependency
       ]) do
    flag = _update_flag(flag, arrival_time, conn, pass)

    # If query is feasible and preferable
    if _feasibility_check(conn, itinerary, arrival_time, pass) &&
         _pref_check(conn, itinerary) && neighbour_map[conn.dst_station] == 0 do
      # Append connection to itinerary
      new_itinerary = add_link(itinerary, conn)
      # Send itinerary to neighbour
      # send_to_neighbour(conn, new_itinerary, dependency)
      # Update neighbour map
      new_neighbour_map = %{neighbour_map | conn.dst_station => 1}

      {[
         {new_neighbour_map, schedule_tail, arrival_time, flag, pass},
         itinerary,
         station_struct,
         dependency
       ], conn, new_itinerary}
    else
      # Pass over connection
      _find_valid_connection([
        {neighbour_map, schedule_tail, arrival_time, flag, pass},
        itinerary,
        station_struct,
        dependency
      ])
    end
  end

  defp _find_valid_connection([
         {neighbour_map, [], arrival_time, flag, :first_pass},
         itinerary,
         station_struct,
         dependency
       ]) do
    # itineraries that start from the next day will be considered in the second
    # pass hence the day has to be incremented by 1.
    new_itinerary = increment_day(itinerary, 1)

    # Start second pass over the schedule.
    next_itinerary([
      {neighbour_map, station_struct.schedule, arrival_time, flag,
       :second_pass},
      new_itinerary,
      station_struct,
      dependency
    ])
  end

  defp _find_valid_connection([
         {_neighbour_map, [], _arrival_time, _flag, :second_pass}
         | _vars_tail
       ]) do
    nil
  end

  # Returns query contained in the itinerary.
  def get_query(itinerary), do: elem(itinerary, 0)

  # Returns the query id of the itinerary.
  def get_query_id(itinerary), do: get_query(itinerary).qid

  # Returns the partial/complete route.
  def get_route(itinerary), do: elem(itinerary, 1)

  # Returns the preferences for the itinerary.
  def get_preference(itinerary), do: elem(itinerary, 2)

  # Increments the the days travelled in the itinerary.
  def increment_day({query, route, preference}, value) do
    new_preference = Map.update!(preference, :day, &(&1 + value))
    {query, route, new_preference}
  end

  # Returns true if the route stops (This does not mean it has reached the final
  # destination) at the the given station argument
  def is_valid_destination(present_station, itinerary) do
    result = present_station == get_last_link(itinerary).dst_station

    Logger.debug(fn ->
      "present_station = #{inspect(present_station)}; result = #{result}"
    end)

    result
  end

  # Returns true if the itinerary is terminal.
  def is_terminal(itinerary) do
    query = get_query(itinerary)
    last_link = get_last_link(itinerary)
    result_is_terminal = query.dst_station == last_link.dst_station

    Logger.debug(fn ->
      "qid = #{query.qid}; result_is_terminal = #{result_is_terminal}"
    end)

    result_is_terminal
  end

  # Returns the last link in the itinerary route.
  def get_last_link(itinerary) do
    [head | _] = elem(itinerary, 1)
    head
  end

  # Adds a link to the present itinerary route.
  def add_link({query, route, preference}, link) do
    new_route = [link | route]

    Logger.debug(fn ->
      "The itinerary = #{inspect({query, route, preference})} got link = #{
        inspect(link)
      } added to it"
    end)

    {query, new_route, preference}
  end

  # Checks the last link generates a selfloop.
  # Makes the assumption that the last station of the route (last link exc)
  # is the source station of the link and that any link won't be a self loop
  # that is having the same source and destination stations
  def check_self_loop({_query, [last_link | route], _preference}),
    do: _match_station(route, last_link)

  def check_self_loop({_query, [], _preference}), do: false

  defp _match_station([], _link), do: false

  defp _match_station([head | tail], link) do
    if head.src_station == link.dst_station do
      true
    else
      _match_station(tail, link)
    end
  end

  # Returns true when iteration must be stopped.
  # Signals iteration to stop when schedule is empty or
  # all neighbours have been visited
  defp stop_fn(neighbours, schedule) do
    Logger.debug(fn -> "All neighbours visited" end)
    schedule == [] || _visited_all_neighbours(neighbours)
  end

  defp _visited_all_neighbours(neighbours) do
    check_if_visited = fn {_, val}, acc ->
      if val == 0 do
        false
      else
        acc
      end
    end

    Enum.reduce(neighbours, false, check_if_visited)
  end

  # Check if preferences match
  def _pref_check(_conn, _itinerary) do
    # Invoke UQCFSM and check for preferences
    true
  end

  defp _update_flag(flag, arrival_time, conn, pass) do
    if pass == :first_pass && flag == nil && arrival_time < conn.dept_time do
      conn
    else
      flag
    end
  end

  # Returns an iterator for valid itineraries to be sent to neighbouring
  # stations.
  def valid_itinerary_iterator(
        {neighbour_map, schedule, arrival_time},
        vars_tail
      ) do
    [{neighbour_map, schedule, arrival_time, nil, :first_pass} | vars_tail]
  end
end
