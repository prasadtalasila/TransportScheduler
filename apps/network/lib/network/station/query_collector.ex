defmodule Station.QueryCollector do
  @moduledoc """
  Provides the implementation for the Collector behaviour using a GenServer.`
  """

  use GenServer, async: true
  require Logger
  @behaviour Station.CollectorBehaviour
  @default_option %{max_itineraries: 10, timeout: 200}
  @end_state %{max_itineraries: 1}

  def start_link(itinerary_acc, opts \\ @default_option, dependency) do
    GenServer.start_link(__MODULE__, [itinerary_acc, opts, dependency])
  end

  def init([itinerary_acc, opts, dependency]) do
    Logger.debug(fn -> "Starting Query Collector" end)
    {:ok, {itinerary_acc, opts, dependency}}
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
  def collect(itinerary_acc, dependency) do
    itinerary_fn = dependency.itinerary
    registry = dependency.registry

    qid = itinerary_fn.get_query_id(itinerary_acc)

    Logger.debug(fn ->
      "Collecting a completed itinerary for query id #{qid}"
    end)

    # Find process id of Query Collector
    qc_pid = registry.lookup_query_id(qid)

    GenServer.cast(qc_pid, {:collect, itinerary_acc})
  end

  def handle_cast(:start, {itinerary_acc, opts, dependency}) do
    registry = dependency.registry
    station = dependency.station
    itinerary_fn = dependency.itinerary

    # Get Source Station
    src_station = itinerary_fn.get_query(itinerary_acc).src_station
    src_pid = registry.lookup_code(src_station)

    # Start Itinerary Search
    station.send_query(src_pid, itinerary_acc)

    {:noreply, {[], opts, itinerary_acc, dependency}, opts.timeout}
  end

  def handle_cast(
        {:collect, completed_itinerary_acc},
        {result, @end_state, itinerary_acc, dependency}
      ) do
    itinerary_fn = dependency.itinerary

    # Add completed itinerary to result,
    itinerary = itinerary_fn.get_itinerary(completed_itinerary_acc)
    result = [itinerary | result]

    # Send Itinerary search result to UQC
    _yield_result(result, itinerary_acc, dependency)

    _unregister_query(itinerary_acc, dependency)

    {:stop, :normal, nil}
  end

  def handle_cast({:collect, _completed_itinerary_acc}, nil) do
    {:noreply, nil}
  end

  def handle_cast(
        {:collect, completed_itinerary_acc},
        {result, opts, itinerary_acc, dependency}
      ) do
    itinerary_fn = dependency.itinerary

    # Add completed itinerary to result,
    itinerary = itinerary_fn.get_itinerary(completed_itinerary_acc)
    result = [itinerary | result]

    # Decrement number of itineraries to be processed
    opts = Map.update!(opts, :max_itineraries, &(&1 - 1))
    {:noreply, {result, opts, itinerary_acc, dependency}, opts.timeout}
  end

  # Send results to UQC and terminate Query Collector if no complete itineraries
  # obtained for a given time (_opts.timeout).
  def handle_info(:timeout, {result, _opts, itinerary_acc, dependency}) do
    # Send Itinerary search result to UQC
    _yield_result(result, itinerary_acc, dependency)

    _unregister_query(itinerary_acc, dependency)

    # Terminate Query Collector process
    {:stop, :normal, nil}
  end

  defp _yield_result(result, itinerary_acc, dependency) do
    itinerary_fn = dependency.itinerary
    uqc = dependency.uqc

    qid = itinerary_fn.get_query_id(itinerary_acc)

    Logger.debug(fn ->
      "Yielding Itinerary Search results for to UQC for query: #{qid}" <>
        " timestamp: #{System.system_time()}"
    end)

    # Send itinerary search result to uqc.
    uqc.receive_search_results(result)
  end

  defp _unregister_query(itinerary_acc, dependency) do
    registry = dependency.registry
    itinerary_fn = dependency.itinerary

    qid = itinerary_fn.get_query_id(itinerary_acc)
    Logger.debug(fn -> "Unregistering query: #{qid}" end)

    # Unregister query using registry
    registry.unregister_query(qid)
  end
end
