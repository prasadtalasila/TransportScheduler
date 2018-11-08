use Mix.Config

IO.puts("In input_parser/config/debug.exs")

config :input_parser,
  stations: "../../data/stations.txt",
  schedule: "../../data/schedule.txt",
  other_means: "../../data/OMT.txt",
  local_variables: "../../data/local_variables.txt"
