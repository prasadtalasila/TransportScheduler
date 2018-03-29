use Mix.Config
IO.puts "using debug config file"

config :logger,
	backends: [
	{LoggerFileBackend, :debug}]

config :logger, :debug,
	level: :debug,
	path: "log/debug.log",
	format: "[$time] $message\n"