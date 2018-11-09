use Mix.Config

IO.puts("In input_parser/config/test.exs")

config :input_parser,
  stations: "../../apps/transport_scheduler/test/data/stations.txt",
  schedule: "../../apps/transport_scheduler/test/data/schedule.txt",
  other_means: "../../apps/transport_scheduler/test/data/OMT.txt",
  local_variables: "../../apps/transport_scheduler/test/data/local_variables.txt"
