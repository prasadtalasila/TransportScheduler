# Module to create a station process and FSM and handle local variable updates

defmodule Station do
  use GenStateMachine

  def start_link() do
    GenStateMachine.start_link(Station, {:nodata, nil})
  end

  # Client-side getter and setter functions

  def update(station,  %StationStruct{} = newVars) do
    GenStateMachine.cast(station, {:update, newVars})
  end

  def get_vars(station) do
    GenStateMachine.call(station, :get_vars)
  end
  
  def get_state(station) do
    GenStateMachine.call(station, :get_state)
  end

  # Client-side message-passing functions
  
  def receive_at_src(nc, src, itinerary) do
    GenStateMachine.cast(src, {:receive_at_src, nc, src, itinerary})
  end

  def send_to_stn(nc, src, dst, itinerary) do
    GenStateMachine.cast(dst, {:receive_at_stn, nc, src, itinerary})
  end

  def send_to_NC(server, itinerary) do
    StationConstructor.receive_from_dest(server, itinerary)
  end

  # Server-side callback functions
  
  def handle_event(:cast, {:update, oldVars}, state, vars) do
    # newVars is assigned values passed to argument oldVars, ie, new values to update local variables with
    schedule = Enum.sort(oldVars.schedule)
    newVars =  %StationStruct{locVars: oldVars.locVars, schedule: schedule, station_number: oldVars.station_number, station_name: oldVars.station_name, pid: oldVars.pid,
			      congestion_low: oldVars.congestion_low, congestion_high: oldVars.congestion_high, choose_fn: oldVars.choose_fn}
    # depending on the state of the station, appropriate FSM state change is made and new values are stored for the station
    case(newVars.locVars.disturbance) do
      "yes"->
	{:next_state, :disturbance, newVars}
      "no" -> 
	case(newVars.locVars.congestion) do
	  "none"->
	    {:next_state, :delay, newVars}
	  "low" ->
	    # congestionDelay is computed using computation function selected based on the choose_fn value
	    congestionDelay = StationFunctions.func(newVars.choose_fn).(newVars.locVars.delay, newVars.congestion_low)
	    {x, updateLocVars} = Map.get_and_update(newVars.locVars, :congestionDelay, fn delay -> {delay, congestionDelay} end)
	    updateVars = %StationStruct{locVars: updateLocVars, schedule: newVars.schedule }
	    {:next_state, :delay, updateVars}
	  "high"->
	    # congestionDelay is computed using computation function selected based on the choose_fn value
	    congestionDelay = StationFunctions.func(newVars.choose_fn).(newVars.locVars.delay, newVars.congestion_high)
	    {x, updateLocVars} = Map.get_and_update(newVars.locVars, :congestionDelay, fn delay -> {delay, congestionDelay} end)
	    updateVars = %StationStruct{locVars: updateLocVars, schedule: newVars.schedule }
	    {:next_state, :delay, updateVars}
	  _	->
	    {:next_state, :delay, newVars}	
	end
      _	   ->
	{:next_state, :delay, newVars}
    end          
  end

  def handle_event({:call, from}, :get_vars, state, vars) do
    # station variables values are returned
    {:next_state, state, vars, [{:reply, from, vars}]}
  end

  def handle_event({:call, from}, :get_state, state, vars) do
    # station FSM state is returned
    {:next_state, state, vars, [{:reply, from, state}]}
  end

  def check_neighbours(schedule, time) do
    # schedule is filtered to reject neighbours with departure time earlier than arrival time at the station for the current itinerary
    nextList = Enum.filter(schedule, fn(x) -> x.dept_time > time end)
  end

  def function(nc, src, itinerary, dstSched) do
    # schedule to reach this destination station is added to itinerary
    newItinerary = List.flatten([itinerary|[dstSched]])
    [query] = Enum.take(newItinerary, 1)
    {:ok, {_, dst}} = StationConstructor.lookup_code(nc, dstSched.dst_station)
    # newItinerary is either returned to NC or sent on to next station to continue additions
    if (dstSched.dst_station == query.dst_station) do
      Station.send_to_NC(nc, newItinerary)
    else
      Station.send_to_stn(nc, src, dst, newItinerary)
    end
  end

  def handle_event(:cast, {:receive_at_src, nc, src, itinerary}, state, vars) do
    [query] = Enum.take(itinerary, 1)
    nextList = Station.check_neighbours(vars.schedule, query.arrival_time)
    # for each neighbouring station, function is called to determine new itinerary additions
    Enum.each(nextList, fn(x) -> function(nc, src, itinerary, x) end)
    {:next_state, state, vars}
  end

  def handle_event(:cast, {:receive_at_stn, nc, src, itinerary}, state, vars) do
    [query] = Enum.take(itinerary, 1)
    [prevStn] = Enum.take(itinerary, -1)
    nextList = Station.check_neighbours(vars.schedule, prevStn.arrival_time)
    # for each neighbouring station, function is called to determine new itinerary additions
    Enum.each(nextList, fn(x) -> function(nc, src, itinerary, x) end)
    {:next_state, state, vars}
  end

  def handle_event(event_type, event_content, state, vars) do
    super(event_type, event_content, state, vars)
  end
end
