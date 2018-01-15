defmodule MockStation do

	use GenServer, async: true

	def start_link(function) do
		  GenServer.start_link(__MODULE__, [function])
	end

	def init(function) do
		{:ok, function}
	end

	def handle_cast({:receive_at_stn, src, itinerary}, function) do
		(elem(function,0)).(src, itinerary)
		{:noreply, function}
	end

end
