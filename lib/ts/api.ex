# Module to define API to obtain and update station variables and find best itinerary

defmodule API do
  use Maru.Router, make_plug: true
  use Maru.Type

  before do
    plug Plug.Parsers,
    pass: ["*/*"],
    json_decoder: Poison,
    parsers: [:json]
  end
  
  namespace :api do
    get do
      {:ok, registry} = StationConstructor.start_link
      {_, _}=API.start_link
      {:ok, pid} = InputParser.start_link
      stn_map = InputParser.get_station_map(pid)
      for stn_key <- Map.keys(stn_map) do
        stn_code = Map.get(stn_map, stn_key)
        stn_struct = InputParser.get_station_struct(pid, stn_key)
        StationConstructor.create(registry, stn_key, stn_code)
        {:ok, {_, station}} = StationConstructor.lookup_name(registry, stn_key)
        Station.update(station, stn_struct)
      end
      API.put(:NC, registry)
      conn|>put_status(200)|>text("Welcome to TransportScheduler API\n")
    end

    namespace :search do
      desc "get itinerary from source to destination"
      params do
        requires :source, type: Integer
        requires :destination, type: Integer
        requires :start_time, type: Integer
        requires :date, type: String
      end
      get do
        # Obtain itinerary
        itinerary=[%{src_station: params[:source], dst_station: params[:destination], arrival_time: params[:start_time]}]
        it1=List.first(itinerary)
        registry=API.get(:NC)
        {:ok, {_, stn}} = StationConstructor.lookup_code(registry, params[:source])
        API.put(it1, [])
        StationConstructor.add_query(registry, it1)
        :timer.sleep(50)
        StationConstructor.send_to_src(registry, stn, itinerary)
        :timer.sleep(500) # need to check
        StationConstructor.del_query(registry, it1)
        conn|>put_status(200)|>json(API.get(it1)|>sort_list)
        API.remove(it1)
      end
    end

    namespace :station do
      namespace :schedule do
        @desc "get a station\'s schedule"
        params do
          requires :station_code, type: Integer
          requires :date, type: String
        end

        get do
          # Get schedule
          registry=API.get(:NC)
          {:ok, {_, station}}=StationConstructor.lookup_code(registry, params[:station_code])
          st_str=Station.get_vars(station)
          res=Map.fetch!(st_str, :schedule)
          conn|>put_status(200)|>json(res)
        end

        namespace :add do
          @desc "add an entry to a station\'s schedule"
          params do
            requires :entry, type: Map do
              requires :vehicleID, type: String
              requires :src_station, type: Integer
              requires :dst_station, type: Integer
              requires :dept_time, type: Integer
              requires :arrival_time, type: Integer
              requires :mode_of_transport, type: String
            end
          end

          post do
            # Add New Schedule
            entry_map=params[:entry]
            registry=API.get(:NC)
            {:ok, {_, station}}=StationConstructor.lookup_code(registry, entry_map.src_station)
            st_str=Station.get_vars(station)
            stn_sched=List.insert_at(st_str.schedule, 0, entry_map)
            st_str=%{st_str|schedule: stn_sched}
            Station.update(station, st_str)
            conn|>put_status(201)|>text("New Schedule added!\n")
          end
        end

        namespace :update do
          @desc "update an existing entry in the station\'s schedule"
          params do
            requires :entry, type: Map do
              requires :vehicleID, type: String
              requires :src_station, type: Integer
              requires :dst_station, type: Integer
              requires :dept_time, type: Integer
              requires :arrival_time, type: Integer
              requires :mode_of_transport, type: String
            end
          end

          put do
            # Update Schedule
            entry_map=params[:entry]
            registry=API.get(:NC)
            {:ok, {_, station}}=StationConstructor.lookup_code(registry, entry_map.src_station)
            st_str=Station.get_vars(station)
            stn_sched=update_list(st_str.schedule, [], entry_map.vehicleID, entry_map, length(st_str.schedule))
            st_str=%{st_str|schedule: stn_sched}
            Station.update(station, st_str)
            conn|>put_status(202)|>text("Schedule Updated!\n")
          end
        end
      end
      
      namespace :state do
        @desc "get state of a station"
        params do
          requires :station_code, type: Integer
        end
        get do
          # Get state vars of that station
          registry=API.get(:NC)
          {:ok, {_, station}}=StationConstructor.lookup_code(registry, params[:station_code])
          st_str=Station.get_vars(station)
          conn|>put_status(200)|>json(st_str.locVars)
        end

        namespace :update do
          @desc "update state of a station"
          params do
            requires :station_code, type: Integer
            requires :local_vars, type: Map do
              requires :congestion, type: String, values: ["none", "low", "high"], default: "none"
              requires :delay, type: Float
              requires :disturbance, type: String, values: ["yes", "no"], default: "no"
            end
          end
          put do
            # Update state vars of that station
            registry=API.get(:NC)
            {:ok, {_, station}}=StationConstructor.lookup_code(registry, params[:station_code])
            st_str=Station.get_vars(station)
            locVarMap=Map.put(params[:local_vars], :congestionDelay, nil)
            st_str=%{st_str|locVars: locVarMap}
            Station.update(station, st_str)
            conn|>put_status(202)|>text("State Updated!\n")
          end
        end
      end

      namespace :create do
        desc "create a new station"
        params do
          requires :local_vars, type: Map do
            requires :congestion, type: String, values: ["none", "low", "high"], default: "none"
            requires :delay, type: Float
            requires :disturbance, type: String, values: ["yes", "no"], default: "no"
          end
          requires :schedule, type: Map do
              requires :vehicleID, type: String
              requires :src_station, type: Integer
              requires :dst_station, type: Integer
              requires :dept_time, type: Integer
              requires :arrival_time, type: Integer
              requires :mode_of_transport, type: String
            #end
          end
          requires :station_code, type: Integer
          requires :station_name, type: String
        end

        post do
          # Add new station's details
          registry=API.get(:NC)
          StationConstructor.create(registry, params[:station_name], params[:station_code])
          {:ok, {_, station}}=StationConstructor.lookup_code(registry, params[:station_code])
          locVarMap=Map.put(params[:local_vars], :congestionDelay, nil)
          stn_str=%StationStruct{locVars: locVarMap, schedule: [params[:schedule]], station_number: params[:station_code], station_name: params[:station_name]}
          Station.update(station, stn_str)
          conn|>put_status(201)|>text("New Station created!\n")
        end
      end
    end
  end

  rescue_from Maru.Exceptions.NotFound do
    conn|>put_status(404)|>json(%{error: "Entry not found"})
  end

  rescue_from Maru.Exceptions.Validation do
    conn|>put_status(405)|>json(%{error: "Validation Exception"})
  end

  rescue_from [MatchError] do
    conn|>put_status(400)|>json(%{error: "Invalid data"})
  end

  rescue_from [RuntimeError] do
    conn|>put_status(500)|>json(%{error: "Runtime Error"})
  end

  rescue_from :all do
    conn|>put_status(500)|>json(%{error: "Server Error"})
  end

  @doc """
  Starts a new agent.
  """
  def start_link do
    Agent.start_link(fn -> %{} end, name: __MODULE__)
  end

  @doc """
  Gets NC pid from map.
  """
  def get(key) do
    Agent.get(__MODULE__, &Map.get(&1, key))
  end

  @doc """
  Puts the pid in the map.
  """
  def put(key, value) do
    Agent.update(__MODULE__, &Map.put(&1, key, value))
  end

  def remove(key) do
    Agent.update(__MODULE__, &Map.delete(&1, key))
  end

  defp sort_list(list) do
    Enum.sort(list, &( (List.last(&1)).arrival_time < (List.last(&2)).arrival_time))
  end

  defp update_list(oldlist, newlist, val, repl, n) when n > 0 do
    [elt|oldlist]=oldlist
    add_entry=if elt.vehicleID===val do
      repl
    else
      elt
    end
    newlist=newlist++[add_entry]
    update_list(oldlist, newlist, val, repl, n-1)
  end

  # Closes the file after reading data of n stations.
  defp update_list(_, newlist, _, _, _) do
    newlist
  end
end
