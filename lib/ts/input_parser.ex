defmodule InputParser do
  defp open_file(filename) do
    File.open(filename, [:read, :utf8])
  end

  defp obtain_station(file, n) when n <= 10 do
    [code | city]=IO.read(file, :line) |> String.trim() |> 
      String.split(" ", parts: 2)
    city=List.to_string(city)
    code=String.to_integer(code)
    IO.puts "City: #{city}, Code: #{code}"
    obtain_station(file, n+1)
  end

  defp obtain_station(file, n) do
    IO.puts "End"
    close_file(file)
  end

  def obtain_stations() do
    {_, file}=open_file("stations.txt")
    obtain_station(file, 1)
  end

  defp obtain_schedule(file, n) when n <= 10 do
    [vehicleID | tail]=IO.read(file, :line) |> String.trim() |>
      String.split(" ", parts: 6)
    vehicleID=String.to_integer(vehicleID)
    [src_station | tail]=tail
    src_station=String.to_integer(src_station)
    [dst_station | tail]=tail
    dst_station=String.to_integer(dst_station)
    [dept_time | tail]=tail
    dept_time=String.to_integer(dept_time)
    [arrival_time | mode_of_transport]=tail
    mode_of_transport=List.to_string(mode_of_transport)
    arrival_time=String.to_integer(arrival_time)
    IO.puts "Vehicle ID: #{vehicleID}, Source: #{src_station}, Destination: #{dst_station}"
    IO.puts "Departure: #{dept_time}, Arrival: #{arrival_time}, Mode: #{mode_of_transport}"
    obtain_schedule(file, n+1)
  end

  defp obtain_schedule(file, n) do
    IO.puts "End"
    close_file(file)
  end

  def obtain_schedules() do
    {_, file}=open_file("schedule.txt")
    obtain_schedule(file, 1)
  end

  defp close_file(file_handle) do
    File.close(file_handle)
  end

end
