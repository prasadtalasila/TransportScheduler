defmodule Storage do
	use GenServer

	def init(variable) do
		{:ok, variable}
	end
	

end
