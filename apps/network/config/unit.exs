use Mix.Config

IO.puts("In network/config/unit.exs")

config :logger,
  level: :debug,
  backends: [
    {LoggerFileBackend, :info},
    {LoggerFileBackend, :warn},
    {LoggerFileBackend, :error},
    {LoggerFileBackend, :debug}
  ]

config :logger, :info,
  level: :info,
  path: "log/info.log",
  format: "[$date][$time]$metadata; $message\n",
  metadata: [:function, :line]

config :logger, :debug,
  level: :debug,
  path: "log/debug.log",
  format: "[$date][$time]$metadata; $message\n",
  metadata: [:function, :line]

config :logger, :error,
  level: :error,
  path: "log/error.log",
  format: "[$date][$time]$metadata; $message\n",
  metadata: [:function, :line]

config :logger, :warn,
  level: :warn,
  path: "log/warn.log",
  format: "[$date][$time]$metadata; $message\n",
  metadata: [:function, :line]
