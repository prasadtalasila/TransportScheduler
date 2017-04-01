defmodule TS do
	use Application

	def start(_type, _args) do
		TS.Supervisor.start_link
	end
end
