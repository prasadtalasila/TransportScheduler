defmodule MockStation do
	@moduledoc """
	Defines the implementation of a Station mock.
	"""

	use GenServer, async: true

	def start_link(function) do
		  GenServer.start_link(__MODULE__, function)
	end

	def init(function) do
		{:ok, function}
	end

	def handle_cast({:receive, itinerary}, function) do
		(elem(function, 0)).(itinerary)
		{:noreply, function}
	end

end
