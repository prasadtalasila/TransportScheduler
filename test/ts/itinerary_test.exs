defmodule ItineraryTest do
	@moduledoc"""
	Module to test Itinerary.
	Tests correctness of the itinerary computation functions defined in Itinerary
	"""

	use ExUnit.Case, async: true
	alias Station.Registry, as: Registry
	alias Station.Collector, as: Collector
	alias Util.Dependency, as: Dependency
	alias Util.Itinerary, as: Itinerary
	alias Util.Query, as: Query
	alias Util.Connection, as: Connection
	alias Util.Preference, as: Preference
	alias Util.StationStruct, as: StationStruct

	test "computes itineraries correctly for connections that start in the current itinerary day" do
		connection = %Connection{vehicleID: "200", src_station: 1, mode_of_transport: "bus",
		dst_station: 2, dept_time: 25_000, arrival_time: 35_000}

		connection_1a = connection
		connection_1b = %Connection{connection | vehicleID: "202"}

		connection_2a = %Connection{connection | vehicleID: "300", dst_station: 3}
		connection_2b = %Connection{connection | vehicleID: "303", dst_station: 3}

		connection_3a = %Connection{connection | vehicleID: "400", dst_station: 4}
		connection_3b = %Connection{connection | vehicleID: "404", dst_station: 4}

		station_state = %StationStruct{loc_vars: %{"delay": 0.38,
			"congestion": "low", "disturbance": "no"},
			schedule: [connection_1a, connection_1b, connection_2a,
			connection_2b, connection_3a, connection_3b],
			station_number: 1, congestion_low: 4, choose_fn: 1}

		itinerary = Itinerary.new(%Query{qid: "0300", src_station: 0,
		dst_station: 3, arrival_time: 0, end_time: 999_999},
			[%Connection{vehicleID: "99", src_station: 0, mode_of_transport: "train",
			dst_station: 1, dept_time: 10_000, arrival_time: 20_000}],
			%Preference{day: 0})

		proper_itinerary_1a = Itinerary.add_link(itinerary, connection_1a)
		proper_itinerary_2a = Itinerary.add_link(itinerary, connection_2a)
		proper_itinerary_3a = Itinerary.add_link(itinerary, connection_3a)

		dependency = %Dependency{station: Station,
		registry: Registery,
		collector: Collector,
		itinerary: Itinerary}

		neighbour_map = %{2 => 0, 3 => 0, 4 => 0}
		schedule = [connection_1a, connection_1b, connection_2a, connection_2b,
		connection_3a, connection_3b]
		arrival_time = 20_000

		vars_tail = [itinerary, station_state, dependency]

		itinerary_iterator = Itinerary.valid_itinerary_iterator(neighbour_map,
		schedule, arrival_time, vars_tail)

		assert {itinerary_iterator, _conn, ^proper_itinerary_1a} =
			Itinerary.next_itinerary(itinerary_iterator)
		assert {itinerary_iterator, _conn, ^proper_itinerary_2a} =
			Itinerary.next_itinerary(itinerary_iterator)
		assert {itinerary_iterator, _conn, ^proper_itinerary_3a} =
			Itinerary.next_itinerary(itinerary_iterator)

		assert Itinerary.next_itinerary(itinerary_iterator) == nil
	end

	test "computes itineraries correctly for connections that on the next day" do
		connection = %Connection{vehicleID: "200", src_station: 1,
		mode_of_transport: "bus", dst_station: 2, dept_time: 25_000,
		arrival_time: 35_000}

		connection_1a = connection
		connection_1b = %Connection{connection | vehicleID: "202"}

		connection_2a = %Connection{connection | vehicleID: "300", dst_station: 3}
		connection_2b = %Connection{connection | vehicleID: "303", dst_station: 3}

		connection_3a = %Connection{connection | vehicleID: "400", dst_station: 4}
		connection_3b = %Connection{connection | vehicleID: "404", dst_station: 4}

		station_state = %StationStruct{loc_vars: %{"delay": 0.38,
			"congestion": "low", "disturbance": "no"},
			schedule: [connection_1a, connection_1b, connection_2a,
			connection_2b, connection_3a, connection_3b],
			station_number: 1, congestion_low: 4, choose_fn: 1}

		itinerary = Itinerary.new(%Query{qid: "0300", src_station: 0,
		dst_station: 3, arrival_time: 0, end_time: 999_999},
			[%Connection{vehicleID: "99", src_station: 0, mode_of_transport: "train",
			dst_station: 1, dept_time: 10_000, arrival_time: 20_000}],
			%Preference{day: 0})

		proper_itinerary_1a = itinerary
		|> Itinerary.add_link(connection_1a)
		|> Itinerary.increment_day(1)
		proper_itinerary_2a = itinerary
		|> Itinerary.add_link(connection_2a)
		|> Itinerary.increment_day(1)
		proper_itinerary_3a = itinerary
		|> Itinerary.add_link(connection_3a)
		|> Itinerary.increment_day(1)

		dependency = %Dependency{station: Station,
		registry: Registry,
		collector: Collector,
		itinerary: Itinerary}

		neighbour_map = %{2 => 0, 3 => 0, 4 => 0}
		schedule = [connection_1a, connection_1b, connection_2a, connection_2b,
		connection_3a, connection_3b]
		arrival_time = 40_000

		vars_tail = [itinerary, station_state, dependency]

		itinerary_iterator = Itinerary.valid_itinerary_iterator(neighbour_map,
		schedule, arrival_time, vars_tail)

		assert {itinerary_iterator, _conn, ^proper_itinerary_1a} =
			Itinerary.next_itinerary(itinerary_iterator)
		assert {itinerary_iterator, _conn, ^proper_itinerary_2a} =
			Itinerary.next_itinerary(itinerary_iterator)
		assert {itinerary_iterator, _conn, ^proper_itinerary_3a} =
			Itinerary.next_itinerary(itinerary_iterator)

		assert Itinerary.next_itinerary(itinerary_iterator) == nil
	end
end
