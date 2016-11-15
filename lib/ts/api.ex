defmodule API do
  use Maru.Router, make_plug: true
  use Maru.Type

  before do
    plug Plug.Parsers,
    pass: ["*/*"],
    json_decoder: Poison,
    parsers: [:urlencoded, :json, :multipart]
  end
  
  namespace :api do
    get do
      {:ok, registry} = StationConstructor.start_link
      #Process.register(registry, :sc)
      {:ok, pid} = InputParser.start_link(10)
      #:global.register_name(StCon, registry)
      #StCon|>IO.inspect
      stn_map = InputParser.get_station_map(pid)
      stn_sched = InputParser.get_schedules(pid)
      for stn_key <- Map.keys(stn_map) do
        stn_code = Map.get(stn_map, stn_key)
        stn_struct = InputParser.get_station_struct(pid, stn_key)
        StationConstructor.create(registry, stn_key, stn_code)
        {:ok, {code, station}} = StationConstructor.lookup_name(registry, stn_key) |> IO.inspect
        #IO.puts Station.get_state(station)
        Station.Update.update(%Station{pid: station}, %StationStruct{})
        #IO.puts Station.get_state(station)
        Station.Update.update(%Station{pid: station}, stn_struct)
      end
      conn|>put_status(200)|>text("Welcome to TransportScheduler API")
    end

    namespace :search do
      desc "get itinerary from source to destination"
      params do
        requires :source, type: Integer
        requires :destination, type: Integer
        requires :start_time, type: String
        requires :date, type: String
      end
      post do
        conn|>put_status(200)|>text("api/search")
        # Obtain itinerary
      end
    end

    namespace :station do
      namespace :schedule do
        @desc "get a station\'s schedule"
        params do
          requires :source, type: Integer
          requires :date, type: String
        end
        get do
          #text(conn, "api/station/schedule")
          # Get station schedule
          #StCon|>IO.inspect
          st_map=obtain_stations(10)
          # params[:source]|>IO.inspect
          city=Map.fetch!(st_map, params[:source])
          #text(conn, "yel")
          #{:ok, registry}=StationConstructor.start_link
          #{:ok, {code, station}}=StationConstructor.lookup_name(city)|>IO.inspect
          #st_str=Station.get_vars(station) |> IO.inspect
          #res=Map.fetch!(st_str, :schedule)
          conn|>put_status(200)|>text(city)
        end
      end
      
      namespace :state do
        @desc "get state of a station"
        params do
          requires :source, type: Integer
        end
        post do
          text(conn, "api/station/state")
          # Get state vars of that station
          st_map=obtain_stations(10)
          city=Map.fetch!(st_map, :source)
          {:ok, :sc}=StationConstructor.start_link
          {:ok, {code, station}}=StationConstructor.lookup_name(:sc, city)
          conn|>put_status(200)|>json(Station.get_vars(station))
        end

        @desc "update state of a station"
        params do
          requires :source, type: Integer
          requires :congestion, type: Atom, values: [:none, :low, :high], default: :none
          requires :delay, type: Float
          requires :disturbance, type: Atom, values: [:yes, :no], default: :no
          at_least_one_of [:congestion, :delay, :disturbance]
        end
        put do
          # Update state vars of that station
        end
      end

      namespace :create do
        desc "create a new station"
        params do
          requires :station, type: Map do
            requires :locVars, type: Json do
              requires :congestion, type: Atom, values: [:none, :low, :high], default: :low
              requires :delay, type: Float
              requires :disturbance, type: Atom, values: [:yes, :no], default: :no
            end
            requires :schedule, type: Json |> List do
              requires :vehicleID, type: Integer
              requires :src_station, type: Integer
              requires :dst_station, type: Integer
              requires :dept_time, type: Integer
              requires :arrival_time, type: Integer
              requires :mode_of_transport, type: String
            end
            requires :station_number, type: Integer
            requires :station_name, type: String
            #requires :congestion_low
            #requires :congestion_high
            #requires :choose_fn
          end
        end
        post do
          text(conn, "api/station/create")
          # Add new station's details
          {:ok, :sc}=StationConstructor.start_link
          StationConstructor.create(:sc, params[:station_name], params[:station_number])
          {:ok, {code, station}} = StationConstructor.lookup(:sc, params[:station_name])
          stn_str=%StationStruct{locVars: %{delay: params[:delay], congestion: params[:congestion], disturbance: params[:disturbance]}, schedule: params[:schedule], station_number: params[:station_number], station_name: params[:station_name]}
          Station.Update.update(%Station{pid: station}, %StationStruct{})
          Station.Update.update(%Station{pid: station}, stn_str)
        end
      end
    end
  end

  rescue_from :all do
    conn |> put_status(500) |> text("Server Error")
  end

  def obtain_stations(n) do
    station_map=Map.new
    {_, file}=File.open("data/stations.txt", [:read, :utf8])
    obtain_station(file, n, station_map)
  end

  # 'Loops' through the n entries of the 'stations.txt' file and saves 
  # The city name and city code as a (key, value) tuples in a map.
  defp obtain_station(file, n, station_map) when n > 0 do
    [code | city]= IO.read(file, :line) |> String.trim() |> String.split(" ", parts: 2)
    city=List.to_string(city)
    code=String.to_integer(code)
    station_map=Map.put(station_map, code, city)
    obtain_station(file, n-1, station_map)
  end

  # Closes the file after reading data of n stations.
  defp obtain_station(file, _, station_map) do
    File.close(file)
    station_map
  end
end
