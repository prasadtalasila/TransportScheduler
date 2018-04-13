defmodule StationCorrectnessTest do
  @moduledoc """
  Tests for the proper interaction of the Station, Station.FSM and
  the Util.Itinerary to correctly perform the itinerary computation.
  """
  use ExUnit.Case, async: true
  import Mox
  alias Util.Dependency, as: Dependency
  alias Util.Itinerary, as: Itinerary
  alias Util.Query, as: Query
  alias Util.Connection, as: Connection
  alias Util.Preference, as: Preference
  alias Util.StationStruct, as: StationStruct

  test "Itinerary only for a single valid connection is forwarded to the next station" do
    station_state = %StationStruct{
      loc_vars: %{delay: 0.38, congestion: "low", disturbance: "no"},
      schedule: [
        %Connection{
          vehicleID: "100",
          src_station: 1,
          mode_of_transport: "bus",
          dst_station: 2,
          dept_time: 25_000,
          arrival_time: 35_000
        },
        %Connection{
          vehicleID: "103",
          src_station: 1,
          mode_of_transport: "bus",
          dst_station: 2,
          dept_time: 25_000,
          arrival_time: 35_000
        }
      ],
      station_number: 1,
      congestion_low: 4,
      choose_fn: 1
    }

    # Station state of Neighbour : %StationStruct{loc_vars: %{"delay": 0.38,
    # 	"congestion": "low", "disturbance": "no"},
    # 	schedule: [], congestion_low: 4, choose_fn: 1}

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

    proper_itinerary =
      Itinerary.add_link(itinerary, %Connection{
        vehicleID: "100",
        src_station: 1,
        mode_of_transport: "bus",
        dst_station: 2,
        dept_time: 25_000,
        arrival_time: 35_000
      })

    improper_itinerary =
      Itinerary.add_link(itinerary, %Connection{
        vehicleID: "103",
        src_station: 1,
        mode_of_transport: "bus",
        dst_station: 2,
        dept_time: 25_000,
        arrival_time: 35_000
      })

    test_proc = self()

    dependency = %Dependency{
      station: MockStation,
      registry: MockRegister,
      collector: MockCollector,
      itinerary: Itinerary
    }

    {:ok, pid} = Station.start_link([station_state, dependency])

    # Define the expectation for the Mock of the Network Constructor
    MockRegister
    |> expect(:lookup_code, fn _ -> test_proc end)
    |> expect(:check_active, fn _ -> true end)

    MockStation
    |> expect(:send_query, 2, fn ^test_proc, itinerary ->
      send(test_proc, {:itinerary_received, itinerary})
    end)

    # Give The Station Process access to mocks defined in the test process
    allow(MockRegister, test_proc, pid)
    allow(MockCollector, test_proc, pid)
    allow(MockStation, test_proc, pid)

    # Send query to station
    Station.send_query(pid, itinerary)
    # Stop station normally
    Station.stop(pid)

    # Wait for the Station process to terminate
    wait_for_process_termination(pid)

    assert_receive({:itinerary_received, ^proper_itinerary})
    refute_receive({:itinerary_received, ^improper_itinerary})
  end

  test "Itinerary only for a single valid connection is forwarded to the next station (testing for multiple stations)" do
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

    station_state = %StationStruct{
      loc_vars: %{delay: 0.38, congestion: "low", disturbance: "no"},
      schedule: [
        connection_1a,
        connection_1b,
        connection_2a,
        connection_2b,
        connection_3a,
        connection_3b
      ],
      station_number: 1,
      congestion_low: 4,
      choose_fn: 1
    }

    # Station state of Neighbour : %StationStruct{loc_vars: %{"delay": 0.38,
    # 	"congestion": "low", "disturbance": "no"},
    # 	schedule: [], congestion_low: 4, choose_fn: 1}

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
    proper_itinerary_1b = Itinerary.add_link(itinerary, connection_1b)
    proper_itinerary_2a = Itinerary.add_link(itinerary, connection_2a)
    proper_itinerary_2b = Itinerary.add_link(itinerary, connection_2b)
    proper_itinerary_3a = Itinerary.add_link(itinerary, connection_3a)
    proper_itinerary_3b = Itinerary.add_link(itinerary, connection_3b)

    test_proc = self()

    dependency = %Dependency{
      station: MockStation,
      registry: MockRegister,
      collector: MockCollector,
      itinerary: Itinerary
    }

    neighbour1 = :c.pid(0, 0, 200)
    neighbour2 = :c.pid(0, 0, 300)
    neighbour3 = :c.pid(0, 0, 400)

    {:ok, pid} = Station.start_link([station_state, dependency])

    # Define the expectation for the Mock of the Network Constructor
    MockRegister
    |> expect(:lookup_code, fn 2 -> neighbour1 end)
    |> expect(:lookup_code, fn 3 -> neighbour2 end)
    |> expect(:lookup_code, fn 4 -> neighbour3 end)
    |> expect(:check_active, fn _ -> true end)

    MockStation
    |> expect(:send_query, 3, fn
      ^neighbour1, itinerary ->
        send(test_proc, {:itinerary_received_in_2, itinerary})

      ^neighbour2, itinerary ->
        send(test_proc, {:itinerary_received_in_3, itinerary})

      ^neighbour3, itinerary ->
        send(test_proc, {:itinerary_received_in_4, itinerary})
    end)

    # Give The Station Process access to mocks defined in the test process
    allow(MockRegister, test_proc, pid)
    allow(MockCollector, test_proc, pid)
    allow(MockStation, test_proc, pid)

    # Send query to station
    Station.send_query(pid, itinerary)
    # Stop station normally
    Station.stop(pid)

    # Wait for the Station process to terminate
    wait_for_process_termination(pid)

    assert_receive({:itinerary_received_in_2, ^proper_itinerary_1a})
    refute_receive({:itinerary_received_in_2, ^proper_itinerary_1b})

    assert_receive({:itinerary_received_in_3, ^proper_itinerary_2a})
    refute_receive({:itinerary_received_in_3, ^proper_itinerary_2b})

    assert_receive({:itinerary_received_in_4, ^proper_itinerary_3a})
    refute_receive({:itinerary_received_in_4, ^proper_itinerary_3b})
  end

  test "The correct itinerary is forwarded to the next station with the
  updated day" do
    station_state = %StationStruct{
      loc_vars: %{delay: 0.38, congestion: "low", disturbance: "no"},
      schedule: [
        %Connection{
          vehicleID: "100",
          src_station: 1,
          mode_of_transport: "bus",
          dst_station: 2,
          dept_time: 25_000,
          arrival_time: 35_000
        }
      ],
      station_number: 1,
      congestion_low: 4,
      choose_fn: 1
    }

    # Station state of Neighbour : %StationStruct{loc_vars: %{"delay": 0.38,
    # 	"congestion": "low", "disturbance": "no"},
    # 	schedule: [], congestion_low: 4, choose_fn: 1}

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
            arrival_time: 86_400
          }
        ],
        %Preference{day: 0}
      )

    proper_itinerary =
      Itinerary.add_link(itinerary, %Connection{
        vehicleID: "100",
        src_station: 1,
        mode_of_transport: "bus",
        dst_station: 2,
        dept_time: 25_000,
        arrival_time: 35_000
      })

    proper_itinerary = Itinerary.increment_day(proper_itinerary, 1)

    test_proc = self()

    dependency = %Dependency{
      station: MockStation,
      registry: MockRegister,
      collector: MockCollector,
      itinerary: Itinerary
    }

    {:ok, pid} = Station.start_link([station_state, dependency])

    # Define the expectation for the Mock of the Network Constructor
    MockRegister
    |> expect(:lookup_code, fn _ -> test_proc end)
    |> expect(:check_active, fn _ -> true end)

    MockStation
    |> expect(:send_query, fn ^test_proc, processed_itinerary ->
      send(test_proc, {:itinerary_received, processed_itinerary})
    end)

    # Give The Station Process access to mocks defined in the test process
    allow(MockRegister, test_proc, pid)
    allow(MockCollector, test_proc, pid)
    allow(MockStation, test_proc, pid)

    # Send query to station
    Station.send_query(pid, itinerary)
    # Stop station normally
    Station.stop(pid)

    # Wait for the Station process to terminate
    wait_for_process_termination(pid)

    assert_receive({:itinerary_received, ^proper_itinerary})
  end

  test "Station Schedule is not changed after processing a query" do
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

    timetable = [
      connection_1a,
      connection_1b,
      connection_2a,
      connection_2b,
      connection_3a,
      connection_3b
    ]

    station_state = %StationStruct{
      loc_vars: %{delay: 0.38, congestion: "low", disturbance: "no"},
      schedule: timetable,
      station_number: 1,
      congestion_low: 4,
      choose_fn: 1
    }

    # Station state of Neighbour : %StationStruct{loc_vars: %{"delay": 0.38,
    # 	"congestion": "low", "disturbance": "no"},
    # 	schedule: [], congestion_low: 4, choose_fn: 1}

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

    test_proc = self()

    dependency = %Dependency{
      station: MockStation,
      registry: MockRegister,
      collector: MockCollector,
      itinerary: Itinerary
    }

    {:ok, pid} = Station.start_link([station_state, dependency])

    # Define the expectation for the Mock of the Network Constructor
    MockRegister
    |> expect(:lookup_code, 3, fn _ -> test_proc end)
    |> expect(:check_active, fn _ -> true end)

    MockStation
    |> expect(:send_query, 3, fn _, _ -> nil end)

    # Give The Station Process access to mocks defined in the test process
    allow(MockRegister, test_proc, pid)
    allow(MockCollector, test_proc, pid)
    allow(MockStation, test_proc, pid)

    # Send query to station
    Station.send_query(pid, itinerary)

    # Assert that the Station
    assert Station.get_timetable(pid) == timetable

    # Stop station normally
    Station.stop(pid)
  end

  def wait_for_process_termination(pid) do
    if Process.alive?(pid) do
      :timer.sleep(10)
      wait_for_process_termination(pid)
    end
  end
end
