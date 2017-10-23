defmodule MockStation do

  use GenServer, async: true

  def init(function) do

		{:ok, function}
	end

  def handle_cast({:receive_at_stn, src, itinerary}, function) do
    function.(itinerary)
		{:noreply, function}
	end

end
