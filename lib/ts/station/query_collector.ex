defmodule Station.QueryCollector do
  @moduledoc """
  Provides the implementation for the Collector behaviour using a GenServer.`
  """

  use GenServer, async: true
  require Logger
  @behaviour Station.CollectorBehaviour
  @default_option %{max_itineraries: 10, timeout: 200}
  @end_state %{max_itineraries: 1}

  def start_link(itinerary, opts \\ @default_option, dependency) do
    GenServer.start_link(__MODULE__, [itinerary, opts, dependency])
  end

  def init([itinerary, opts, dependency]) do
    Logger.debug(fn -> "Starting Query Collector" end)
    {:ok, {itinerary, opts, dependency}}
  end

  def stop(pid) do
    Logger.debug(fn -> "Terminating Query Collector normally" end)
    GenServer.stop(pid, :normal)
  end

  # Initialise Itinerary search
  def search_itinerary(pid) do
    Logger.debug(fn -> "Initialising Itinerary Search." end)
    GenServer.cast(pid, :start)
  end

  # Send completed itinerary to Query Collector.
  def collect(itinerary, dependency) do
    itinerary_fn = dependency.itinerary
    registry = dependency.registry

    qid = itinerary_fn.get_query_id(itinerary)

    Logger.debug(fn ->
      "Collecting a completed itinerary for query id #{qid}"
    end)

    # Find process id of Query Collector
    qc_pid = registry.lookup_query_id(qid)

    GenServer.cast(qc_pid, {:collect, itinerary})
  end

  defp _yield_result(result, itinerary, dependency) do
    itinerary_fn = dependency.itinerary
    uqc = dependency.uqc

    qid = itinerary_fn.get_query_id(itinerary)

    Logger.debug(fn ->
      "Yielding Itinerary Search results for to UQC for query: #{qid}"
    end)

    # Send itinerary search result to uqc.
    uqc.receive_search_results(result)
  end

  defp _unregister_query(itinerary, dependency) do
    registry = dependency.registry
    itinerary_fn = dependency.itinerary

    qid = itinerary_fn.get_query_id(itinerary)
    Logger.debug(fn -> "Unregistering query: #{qid}" end)

    # Unregister query using registry
    registry.unregister_query(qid)
  end

  def handle_cast(:start, {itinerary, opts, dependency}) do
    registry = dependency.registry
    station = dependency.station
    itinerary_fn = dependency.itinerary

    # Get Source Station
    src_station = itinerary_fn.get_query(itinerary).src_station
    src_pid = registry.lookup_code(src_station)

    # Start Itinerary Search
    station.send_query(src_pid, itinerary)

    {:noreply, {[], opts, itinerary, dependency}, opts.timeout}
  end

  def handle_cast(
        {:collect, completed_itinerary},
        {result, @end_state, itinerary, dependency}
      ) do
    # Add completed itinerary to result,
    result = [completed_itinerary | result]

    # Send Itinerary search result to UQC
    _yield_result(result, itinerary, dependency)

    _unregister_query(itinerary, dependency)

    {:stop, :normal, nil}
  end

  def handle_cast({:collect, _completed_itinerary}, nil) do
    {:noreply, nil}
  end

  def handle_cast(
        {:collect, completed_itinerary},
        {result, opts, itinerary, dependency}
      ) do
    # Add completed itinerary to result,
    result = [completed_itinerary | result]

    # Decrement number of itineraries to be processed
    opts = Map.update!(opts, :max_itineraries, &(&1 - 1))
    {:noreply, {result, opts, itinerary, dependency}, opts.timeout}
  end

  # Send results to UQC and terminate Query Collector if no complete itineraries
  # obtained for a given time (_opts.timeout).
  def handle_info(:timeout, {result, _opts, itinerary, dependency}) do
    # Send Itinerary search result to UQC
    _yield_result(result, itinerary, dependency)

    _unregister_query(itinerary, dependency)

    # Terminate Query Collector process
    {:stop, :normal, nil}
  end
end
