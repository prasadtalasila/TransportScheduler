defmodule InputParser do
  use GenServer

  # Client-side functions

  def start_link do
    GenServer.start_link(__MODULE__, :ok)
  end

  def get_station_map(pid) do
    GenServer.call(pid, :get_station_map)
  end

  def get_schedules(pid) do
    GenServer.call(pid, :get_schedules)
  end

  def get_schedule(pid, code) do
    GenServer.call(pid, {:get_schedule, code})
  end

  def get_local_variables(pid, code) do
    GenServer.call(pid, {:get_loc_vars, code})
  end

  def get_city_code(pid, city) do
    GenServer.call(pid, {:get_city_code, city})
  end
  
  def get_station_struct(pid, city) do
    s=%StationStruct{}
    code=get_city_code(pid, city)
    %{s | locVars: Map.merge(s.locVars, get_local_variables(pid, code)), 
      schedule: get_schedule(pid, code),
      station_number: code, station_name: city}
  end

  def stop(pid) do
    GenServer.stop(pid, :normal, 100)
  end

  # Server-side callback functions

  def init(:ok) do
    # values are read from input data files
    station_map=obtain_stations()
    schedule=obtain_schedules()
    locvarmap=obtain_loc_var_map()
    {:ok, {station_map, schedule, locvarmap}}
  end

  def handle_call(:get_station_map, _from, {station_map, _, _}=state) do
    # Map of station name and station code returned
    {:reply, station_map, state}
  end

  def handle_call(:get_schedules, _from, {_, schedule, _}=state) do
    # schedules for a station are returned
    {:reply, schedule, state}
  end

  def handle_call({:get_loc_vars, code}, _from, {_, _, locvarmap}=state) do
    # local variables for a station are returned
    {:reply, Map.fetch!(locvarmap, code), state}
  end

  def handle_call({:get_city_code, city}, _from, {station_map, _, _}=state) do
     # station code given station name is returned
   {:reply, Map.fetch!(station_map, city), state}
  end

  def handle_call({:get_schedule, code}, _from, {_, schedule, _}=state) do
    # schedules for a station and destination are returned
    {:reply, Keyword.get_values(schedule, String.to_atom(Integer.to_string(code))), state}
  end

  def terminate(reason, state) do
    super(reason, state)
  end

  # Helper functions

  # Obtains Map of stations
  def obtain_stations do
    station_map=Map.new
    {_, file}=open_file("data/stations.txt")
    #n = IO.read file, [:line] |> String.trim |> String.to_integer
    n = 2264
    obtain_station(file, n, station_map)
  end

  # Obtains Map of schedules
  def obtain_schedules do
    schedule=Keyword.new
    {_, file}=open_file("data/schedule.txt")
    #n = IO.read file, [:line] |> String.trim |> String.to_integer
    n = 56555
    obtain_schedule(file, n, schedule)
  end

  # Obtains Map of local variables
  def obtain_loc_var_map do
    locvarmap=Map.new
    {_, file}=open_file("data/local_variables.txt")
    #n = IO.read file, [:line] |> String.trim |> String.to_integer
    n = 2264
    obtain_loc_vars(file, n, locvarmap)
  end

  # Opens the file specified by 'filename' parameter.
  defp open_file(filename) do
    File.open(filename, [:read, :utf8])
  end

  # 'Loops' through the n entries of the 'stations.txt' file and saves 
  # The city name and city code as a (key, value) tuples in a map.
  defp obtain_station(file, n, station_map) when n > 0 do
    [code | city]= IO.read(file, :line) |> String.trim() |> String.split(" ", parts: 2)
    city=List.to_string(city)
    code=String.to_integer(code)
    station_map=Map.put(station_map, city, code)
    obtain_station(file, n-1, station_map)
  end

  # Closes the file after reading data of n stations.
  defp obtain_station(file, _, station_map) do
    close_file(file)
    station_map
  end

  # 'Loops' through the n entries of the 'schedule.txt' file and saves 
  # The variables as entries in a data structure called Keyword.
  defp obtain_schedule(file, n, schedule) when n > 0 do
    [vehicle_id | tail]=IO.read(file, :line) |> String.trim() |> String.split(" ", parts: 6)
    [srcStation | tail]=tail
    srcStation=String.to_integer(srcStation)
    [dstStation | tail]=tail
    dstStation=String.to_integer(dstStation)
    [deptTime | tail]=tail
    deptTime=String.to_integer(deptTime)
    [arrivalTime | modeOfTransport]=tail
    modeOfTransport=List.to_string(modeOfTransport)
    arrivalTime=String.to_integer(arrivalTime)
    sched=Map.new |> Map.put(:vehicleID, vehicle_id) |> Map.put(:src_station, srcStation)
      |> Map.put(:dst_station, dstStation) |> Map.put(:dept_time, deptTime) |>
      Map.put(:arrival_time, arrivalTime) |> Map.put(:mode_of_transport, modeOfTransport)
    schedule=Enum.into(schedule, [{Integer.to_string(srcStation) |> String.to_atom, sched}])
    obtain_schedule(file, n-1, schedule)
  end

  # Closes the file after reading schedules of n stations.
  defp obtain_schedule(file, _, schedule) do
    close_file(file)
    schedule
  end

  # 'Loops' through the n entries of the 'local_variables.txt' file and saves 
  # The local variables as (key, value) tuples in a map.
  defp obtain_loc_vars(file, n, locvarmap) when n > 0 do
    [stationCode | tail]=IO.read(file, :line) |> String.trim() |> String.split(" ", parts: 7)
    stationCode=String.to_integer(stationCode)
    [local_var1 | tail]=tail
    local_var1=String.to_atom(local_var1)
    [val1 | tail]=tail
    val1=String.to_float(val1)
    [local_var2 | tail]=tail
    local_var2=String.to_atom(local_var2)
    [val2 | tail]=tail
    [local_var3 | val3]=tail
    local_var3=String.to_atom(local_var3)
    val3=List.to_string(val3)
    vals=Map.new |> Map.put(local_var1, val1) |> Map.put(local_var2, val2)
      |> Map.put(local_var3, val3)
    locvarmap=Map.put(locvarmap, stationCode, vals)
    obtain_loc_vars(file, n-1, locvarmap)
  end

  # Closes the file after reading the local variables values of n stations.
  defp obtain_loc_vars(file, _, locvarmap) do
    close_file(file)
    locvarmap
  end

  # Closes the file handle specified by 'file_handle' parameter.
  defp close_file(file_handle) do
    File.close(file_handle)
  end

end
