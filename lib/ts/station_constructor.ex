defmodule StationConstructor do
	@moduledoc """
	Module to create registry process for monitoring all station processes, i.e.,
	Network Constructor NC
	"""
	use GenServer, async: true

	def add_query(server, query, conn) do
		GenServer.cast(server, {:add_query, query, conn})
	end

	def del_query(server, query) do
		GenServer.cast(server, {:del_query, query})
	end

	def check_active(server, query) do
		GenServer.call(server, {:check_active, query})
	end

	def return_queries(server) do
		GenServer.call(server, {:return_queries})
	end

	def put_queries(server, queries) do
		GenServer.cast(server, {:put_queries, queries})
	end

	# Client-side NC management functions
	def start_link(name) do
		GenServer.start_link(__MODULE__, :ok, name: name)
	end

	def create(server, name, code) do
		GenServer.cast(server, {:create, name, code})
	end

	def stop(server) do
		GenServer.stop(server, :normal)
	end

	# Client-side lookup functions

	def lookup_name(server, name) do
		GenServer.call(server, {:lookup_name, name})
	end

	def lookup_code(server, code) do
		GenServer.call(server, {:lookup_code, code})
	end

	# Client-side message-passing functions

	def send_to_src(src, dest, itinerary) do
		Station.receive_at_src(src, dest, itinerary)
	end

	#def receive_from_dest(server, itinerary) do
		#GenServer.cast(server, {:msg_received_at_NC, itinerary})
	#end

	# Server-side callback functions

	def init(:ok) do
		# new registry process for NC started
		names=%{}
		codes=%{}
		refs=%{}
		queries=%{}
		{:ok, {names, codes, refs, queries}}
	end

	def handle_call({:return_queries}, _from, {_, _, _, queries}=state) do
		# return the list of active queries
		{:reply, queries, state}
	end

	def handle_call({:lookup_name, name}, _from, {names, _, _, _}=state) do
		# station name lookup from Map in registry
		{:reply, Map.fetch(names, name), state}
	end

	def handle_call({:lookup_code, code}, _from, {_, codes, _, _}=state) do
		# station code lookup from Map in registry
		{:reply, Map.fetch(codes, code), state}
	end

	def handle_call({:check_active, query}, _from, {_, _, _, queries}=state) do
		if Map.get(queries, query)===nil do
			{:reply, false, state}
		else
			{:reply, true, state}
		end
	end

	#def handle_cast({:msg_received_at_NC, itinerary}, {names, codes, refs,
	# queries}) do
		# feasible itineraries returned to NC are displayed
#API.start_link
#queries=if (length(Map.keys(queries))!=0) do
#query=List.first(itinerary)|>Map.delete(:day)
#conn=Map.get(queries, query)
#list=API.get(conn)
#b#ool=if list===nil do
###false
 ##     else
###(length(list)<20)
 ##     end
 ##     case bool do
###true ->
##list=list++[itinerary]
#A#PI.put(conn, query, list)
##qpt=System.system_time(:milliseconds)-(API.get(query)|>elem(1))
#API.put({query, "time"}, qpt)
#I#O.inspect query
###IO.puts "#{qpt}"
###queries
 ##       false ->
###if API.member(query) do
###send(API.get(query)|>elem(0), :release)
 ##         end
 ##         Map.delete(queries, query)
 #     end
	#  else
 ##     queries
 #   end
		#{:noreply, {names, codes, refs, queries}}
	#end

	def handle_cast({:put_queries, queries}, {names, codes, refs, _}) do
		{:noreply, {names, codes, refs, queries}}
	end

	def handle_cast({:create, name, code}, {names, codes, refs, queries}=state) do
		# new station process created if not in NC registry
		if Map.has_key?(names, name) do
			{:noreply, state}
		else
			{:ok, pid}=TS.Station.Supervisor.start_station
			ref=Process.monitor(pid)
			refs=Map.put(refs, ref, {name, code})
			names=Map.put(names, name, {code, pid})
			codes=Map.put(codes, code, {name, pid})
			{:noreply, {names, codes, refs, queries}}
		end
	end

	def handle_cast({:add_query, query, conn}, {names, codes, refs, queries}) do
		queries=Map.put(queries, query, conn)
		{:noreply, {names, codes, refs, queries}}
	end

	def handle_cast({:del_query, query}, {names, codes, refs, queries}) do
		queries=Map.delete(queries, query)
		{:noreply, {names, codes, refs, queries}}
	end

	def handle_info({:DOWN, ref, :process, _pid, _reason}, {names, codes, refs, queries}) do
		{{name, code}, refs}=Map.pop(refs, ref)
		names=Map.delete(names, name)
		codes=Map.delete(codes, code)
		StationConstructor.create(StationConstructor, name, code)
		{:noreply, {names, codes, refs, queries}}
	end

	def handle_info(_msg, state) do
		{:noreply, state}
	end
end
