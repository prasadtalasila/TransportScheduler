defmodule InputParser do
  defp open_file(filename) do
    File.open(filename, [:read, :utf8])
  end

  defp obtain_station(file, n, station_map) when n > 0 do
    [code | city]=IO.read(file, :line) |> String.trim() |> 
      String.split(" ", parts: 2)
    city=List.to_string(city)
    code=String.to_integer(code)
    station_map=Map.put(station_map, code, city)
    obtain_station(file, n-1, station_map)
  end

  defp obtain_station(file, _, station_map) do
    close_file(file)
    station_map
  end

  defp obtain_schedule(file, n, schedule) when n > 0 do
    [vehicle_id | tail]=IO.read(file, :line) |> String.trim() |>
      String.split(" ", parts: 6)
    vehicle_id=String.to_integer(vehicle_id)
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
    schedule=Keyword.put(schedule, Integer.to_string(srcStation) |> String.to_atom, sched)
    obtain_schedule(file, n-1, schedule)
  end

  defp obtain_schedule(file, _, schedule) do
    close_file(file)
    schedule
  end

  defp obtain_loc_vars(file, n, locvarmap) when n > 0 do
    [stationCode | tail]=IO.read(file, :line) |> String.trim() |>
      String.split(" ", parts: 7)
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

  defp obtain_loc_vars(file, _, locvarmap) do
    close_file(file)
    locvarmap
  end

  defp close_file(file_handle) do
    File.close(file_handle)
  end

  @doc """
  Returns a map of the stations
  """
  def obtain_stations(n) do
    station_map=Map.new
    {_, file}=open_file("stations.txt")
    obtain_station(file, n, station_map)
  end

    @doc """
  Returns a map of the schedule
  """
  def obtain_schedules(n) do
    schedule=Keyword.new
    {_, file}=open_file("schedule.txt")
    obtain_schedule(file, n, schedule)
  end

  @doc """
  Returns a map of the local variables
  """
  def obtain_loc_var_map(n) do
    locvarmap=Map.new
    {_, file}=open_file("local_variables.txt")
    obtain_loc_vars(file, n, locvarmap)
  end

end
