defmodule ItineraryTest do
  @moduledoc """
  Module to test Itinerary.
  Tests correctness of the itinerary computation functions defined in Itinerary
  """

  use ExUnit.Case, async: true
  alias Util.Connection, as: Connection
  alias Util.Dependency, as: Dependency
  alias Util.Itinerary, as: Itinerary
  alias Util.Preference, as: Preference
  alias Util.Query, as: Query
  alias Util.StationStruct, as: StationStruct

  test "updates days travelled of an itinerary correctly" do
    connection = %Connection{
      vehicleID: "200",
      src_station: 1,
      mode_of_transport: "bus",
      dst_station: 2,
      dept_time: 25_000,
      arrival_time: 100_000
    }

    itinerary = get_itinerary(route: [connection])

    {{_query, _route, preference}, arrival_time} =
      Itinerary.update_days_travelled(itinerary)

    assert Itinerary.get_preference(itinerary).day == 0
    assert preference.day == 1
    assert arrival_time == Integer.mod(connection.arrival_time, 86_400)
  end

  test "check_self_loop returns true when the adding a link will result in a self loop" do
    start_station = 2
    itinerary_length = 5
    self_loop_station = start_station + itinerary_length - 2
    non_self_loop_station = start_station + itinerary_length
    itinerary = get_itinerary(itinerary_length, start_station)

    self_loop_connection = %Connection{
      vehicleID: "200",
      src_station: start_station + itinerary_length - 1,
      mode_of_transport: "bus",
      dst_station: self_loop_station,
      dept_time: 25_000,
      arrival_time: 100_000
    }

    self_loop_itinerary = Itinerary.add_link(itinerary, self_loop_connection)

    non_self_loop_connection = %Connection{
      vehicleID: "200",
      src_station: start_station + itinerary_length - 1,
      mode_of_transport: "bus",
      dst_station: non_self_loop_station,
      dept_time: 25_000,
      arrival_time: 100_000
    }

    non_self_loop_itinerary =
      Itinerary.add_link(itinerary, non_self_loop_connection)

    assert Itinerary.check_self_loop(self_loop_itinerary) == true

    assert Itinerary.check_self_loop(non_self_loop_itinerary) == false
  end

  test "Check if valid_itinerary_iterator returns iterator of valid format" do
    neighbour_map = :neighbour_map
    schedule = :schedule
    arrival_time = :arrival_time
    vars_tail = :vars_tail

    valid_iterator = [
      {:neighbour_map, :schedule, :arrival_time, nil, :first_pass} | :vars_tail
    ]

    assert Itinerary.valid_itinerary_iterator(
             {neighbour_map, schedule, arrival_time},
             vars_tail
           ) == valid_iterator
  end

  test "iterator returns nil for empty schedule" do
    station_state = get_station_struct([])

    itinerary =
      Itinerary.new(
        %Query{
          qid: "0300",
          src_station: 1,
          dst_station: 3,
          arrival_time: 0,
          end_time: 999_999
        },
        [],
        %Preference{day: 0}
      )

    dependency = get_dependency()

    neighbour_map = %{2 => 0, 3 => 0, 4 => 0}

    arrival_time = 20_000

    schedule = []

    vars_tail = [itinerary, station_state, dependency]

    itinerary_iterator =
      Itinerary.valid_itinerary_iterator(
        {neighbour_map, schedule, arrival_time},
        vars_tail
      )

    assert Itinerary.next_itinerary(itinerary_iterator) == nil
  end

  test "iterator returns nil when all neighbours have been traversed" do
    connection = %Connection{
      vehicleID: "202",
      src_station: 1,
      mode_of_transport: "bus",
      dst_station: 2,
      dept_time: 25_000,
      arrival_time: 35_000
    }

    connection_a = connection
    connection_b = %Connection{connection | vehicleID: "203", dst_station: 3}
    connection_c = %Connection{connection | vehicleID: "204", dst_station: 4}

    schedule = [connection_a, connection_b, connection_c]

    station_state = get_station_struct(schedule)

    itinerary =
      Itinerary.new(
        %Query{
          qid: "0300",
          src_station: 1,
          dst_station: 3,
          arrival_time: 0,
          end_time: 999_999
        },
        [],
        %Preference{day: 0}
      )

    dependency = get_dependency()

    neighbour_map = %{2 => 1, 3 => 1, 4 => 1}

    arrival_time = 20_000

    vars_tail = [itinerary, station_state, dependency]

    itinerary_iterator =
      Itinerary.valid_itinerary_iterator(
        {neighbour_map, schedule, arrival_time},
        vars_tail
      )

    assert Itinerary.next_itinerary(itinerary_iterator) == nil
  end

  test "computes itineraries correctly for connections that start in the current itinerary day" do
    connection = %Connection{
      vehicleID: "200",
      src_station: 1,
      mode_of_transport: "bus",
      dst_station: 2,
      dept_time: 25_000,
      arrival_time: 35_000
    }

    connection_1a = connection
    connection_1b = %Connection{connection | vehicleID: "202"}

    connection_2a = %Connection{connection | vehicleID: "300", dst_station: 3}
    connection_2b = %Connection{connection | vehicleID: "303", dst_station: 3}

    connection_3a = %Connection{connection | vehicleID: "400", dst_station: 4}
    connection_3b = %Connection{connection | vehicleID: "404", dst_station: 4}

    station_state =
      get_station_struct([
        connection_1a,
        connection_1b,
        connection_2a,
        connection_2b,
        connection_3a,
        connection_3b
      ])

    itinerary =
      Itinerary.new(
        %Query{
          qid: "0300",
          src_station: 0,
          dst_station: 3,
          arrival_time: 0,
          end_time: 999_999
        },
        [
          %Connection{
            vehicleID: "99",
            src_station: 0,
            mode_of_transport: "train",
            dst_station: 1,
            dept_time: 10_000,
            arrival_time: 20_000
          }
        ],
        %Preference{day: 0}
      )

    proper_itinerary_1a = Itinerary.add_link(itinerary, connection_1a)
    proper_itinerary_2a = Itinerary.add_link(itinerary, connection_2a)
    proper_itinerary_3a = Itinerary.add_link(itinerary, connection_3a)

    dependency = get_dependency()

    neighbour_map = %{2 => 0, 3 => 0, 4 => 0}

    schedule = [
      connection_1a,
      connection_1b,
      connection_2a,
      connection_2b,
      connection_3a,
      connection_3b
    ]

    arrival_time = 20_000

    vars_tail = [itinerary, station_state, dependency]

    itinerary_iterator =
      Itinerary.valid_itinerary_iterator(
        {neighbour_map, schedule, arrival_time},
        vars_tail
      )

    assert {itinerary_iterator, _conn, ^proper_itinerary_1a} =
             Itinerary.next_itinerary(itinerary_iterator)

    assert {itinerary_iterator, _conn, ^proper_itinerary_2a} =
             Itinerary.next_itinerary(itinerary_iterator)

    assert {itinerary_iterator, _conn, ^proper_itinerary_3a} =
             Itinerary.next_itinerary(itinerary_iterator)

    assert Itinerary.next_itinerary(itinerary_iterator) == nil
  end

  test "computes itineraries correctly for connections that on the next day" do
    connection = %Connection{
      vehicleID: "200",
      src_station: 1,
      mode_of_transport: "bus",
      dst_station: 2,
      dept_time: 25_000,
      arrival_time: 35_000
    }

    connection_1a = connection
    connection_1b = %Connection{connection | vehicleID: "202"}

    connection_2a = %Connection{connection | vehicleID: "300", dst_station: 3}
    connection_2b = %Connection{connection | vehicleID: "303", dst_station: 3}

    connection_3a = %Connection{connection | vehicleID: "400", dst_station: 4}
    connection_3b = %Connection{connection | vehicleID: "404", dst_station: 4}

    station_state =
      get_station_struct([
        connection_1a,
        connection_1b,
        connection_2a,
        connection_2b,
        connection_3a,
        connection_3b
      ])

    itinerary =
      Itinerary.new(
        %Query{
          qid: "0300",
          src_station: 0,
          dst_station: 3,
          arrival_time: 0,
          end_time: 999_999
        },
        [
          %Connection{
            vehicleID: "99",
            src_station: 0,
            mode_of_transport: "train",
            dst_station: 1,
            dept_time: 10_000,
            arrival_time: 20_000
          }
        ],
        %Preference{day: 0}
      )

    proper_itinerary_1a =
      itinerary
      |> Itinerary.add_link(connection_1a)
      |> Itinerary.increment_day(1)

    proper_itinerary_2a =
      itinerary
      |> Itinerary.add_link(connection_2a)
      |> Itinerary.increment_day(1)

    proper_itinerary_3a =
      itinerary
      |> Itinerary.add_link(connection_3a)
      |> Itinerary.increment_day(1)

    dependency = get_dependency()

    neighbour_map = %{2 => 0, 3 => 0, 4 => 0}

    schedule = [
      connection_1a,
      connection_1b,
      connection_2a,
      connection_2b,
      connection_3a,
      connection_3b
    ]

    arrival_time = 40_000

    vars_tail = [itinerary, station_state, dependency]

    itinerary_iterator =
      Itinerary.valid_itinerary_iterator(
        {neighbour_map, schedule, arrival_time},
        vars_tail
      )

    assert {itinerary_iterator, _conn, ^proper_itinerary_1a} =
             Itinerary.next_itinerary(itinerary_iterator)

    assert {itinerary_iterator, _conn, ^proper_itinerary_2a} =
             Itinerary.next_itinerary(itinerary_iterator)

    assert {itinerary_iterator, _conn, ^proper_itinerary_3a} =
             Itinerary.next_itinerary(itinerary_iterator)

    assert Itinerary.next_itinerary(itinerary_iterator) == nil
  end

  def make_itinerary do
    Itinerary.new(
      %Query{
        qid: "0300",
        src_station: 0,
        dst_station: 3,
        arrival_time: 0,
        end_time: 999_999
      },
      [
        %Connection{
          vehicleID: "99",
          src_station: 0,
          mode_of_transport: "train",
          dst_station: 1,
          dept_time: 10_000,
          arrival_time: 20_000
        }
      ],
      %Preference{day: 0}
    )
  end

  def get_itinerary(route: route) do
    Itinerary.new(
      %Query{
        qid: "0300",
        src_station: 0,
        dst_station: 3,
        arrival_time: 0,
        end_time: 999_999
      },
      route,
      %Preference{day: 0}
    )
  end

  def get_itinerary(n, start) when n >= 0 do
    qid = Integer.to_string(:rand.uniform(10_000))
    src_station = start
    dst_station = src_station + n
    arrival_time = :rand.uniform(1000)
    end_time = :rand.uniform(1000)

    query = %Query{
      qid: qid,
      src_station: src_station,
      dst_station: dst_station,
      arrival_time: arrival_time,
      end_time: end_time
    }

    mode_of_transport = Integer.to_string(:rand.uniform(10_000))
    day = :rand.uniform(10)
    preference = %Preference{day: day, mode_of_transport: mode_of_transport}
    route = loop(n, [], src_station)
    {query, route, preference}
  end

  def loop(n, acc, src_station) when n > 0 do
    vid = Integer.to_string(:rand.uniform(10_000))
    mode_of_transport = Integer.to_string(:rand.uniform(10_000))
    dst_station = src_station + 1
    dept_time = :rand.uniform(10)
    arrival_time = :rand.uniform(10)

    connection = %Connection{
      vehicleID: vid,
      src_station: src_station,
      mode_of_transport: mode_of_transport,
      dst_station: dst_station,
      dept_time: dept_time,
      arrival_time: arrival_time
    }

    loop(n - 1, [connection | acc], dst_station)
  end

  def loop(0, acc, _), do: acc

  def get_dependency do
    %Dependency{
      station: Station,
      registry: Registry,
      collector: Collector,
      itinerary: Itinerary
    }
  end

  def get_station_struct(schedule) do
    %StationStruct{
      loc_vars: %{delay: 0.38, congestion: "low", disturbance: "no"},
      schedule: schedule,
      station_number: 1,
      congestion_low: 4,
      choose_fn: 1
    }
  end
end
