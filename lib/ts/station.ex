# Module to create station process and FSM and handle local variable updates

defmodule Station do
  use GenStateMachine

  # Client

  def start_link() do
    GenStateMachine.start_link(Station, {:nodata, nil})
  end

  def update(station, newVars) do
    GenStateMachine.cast(station, newVars)
  end

  def get_vars(station) do
    GenStateMachine.call(station, :get_vars)
  end
  
  def get_state(station) do
    GenStateMachine.call(station, :get_state)
  end

  def send_message_stn(src, dst) do
    GenStateMachine.call(dst, :send_msg_stn)
  end

  # Server (callbacks)

  def handle_event(:cast, newVars, state, vars) do
    case(newVars.locVars.disturbance) do
      "yes"	->
	{:next_state, :disturbance, newVars}
      "no"	-> 
	case(newVars.locVars.congestion) do
	  "none"	->
	    {:next_state, :delay, newVars}
	  "low"		->
	    # {congestionDelay, y} = Code.eval_string(newVars.congestion_low, [delay: newVars.locVars.delay])
	    # congestionDelay = StationFunctions.compute_congestion_delay1(newVars.locVars.delay, newVars.congestion_low)
	    congestionDelay = StationFunctions.func(newVars.choose_fn).(newVars.locVars.delay, newVars.congestion_low)

	    {x, updateLocVars} = Map.get_and_update(newVars.locVars, :congestionDelay, fn delay -> {delay, congestionDelay} end)
	    updateVars = %StationStruct{locVars: updateLocVars, schedule: newVars.schedule }
	    {:next_state, :delay, updateVars}
	  "high"	->
	    # {congestionDelay, y} = Code.eval_string(newVars.congestion_high, [delay: newVars.locVars.delay])
	    # congestionDelay = StationFunctions.compute_congestion_delay1(newVars.locVars.delay, newVars.congestion_high)
	    congestionDelay = StationFunctions.func(newVars.choose_fn).(newVars.locVars.delay, newVars.congestion_high)

	    {x, updateLocVars} = Map.get_and_update(newVars.locVars, :congestionDelay, fn delay -> {delay, congestionDelay} end)
	    updateVars = %StationStruct{locVars: updateLocVars, schedule: newVars.schedule }
	    {:next_state, :delay, updateVars}
	  _				->
	    {:next_state, :delay, newVars}	
	end
      _			->
	{:next_state, :delay, newVars}
    end          
  end

  def handle_event({:call, from}, :get_vars, state, vars) do
    {:next_state, state, vars, [{:reply, from, vars}]}
  end

  def handle_event({:call, from}, :get_state, state, vars) do
    {:next_state, state, vars, [{:reply, from, state}]}
  end

  def handle_event({:call, from}, :send_msg_stn, state, vars) do
    {:next_state, state, vars, [{:reply, from, :msg_sent_to_stn}]}
  end

  def handle_event(event_type, event_content, state, vars) do
    # Call the default implementation from GenStateMachine
    super(event_type, event_content, state, vars)
  end
end
