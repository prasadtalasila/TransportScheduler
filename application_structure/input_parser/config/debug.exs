use Mix.Config
IO.puts "Loading from config/debug.exs in input parser."

config :logger,
	backends: [
	{LoggerFileBackend, :debug}]

config :logger, :debug,
	level: :debug,
	path: "log/debug.log",
	format: "[$time] $message\n"