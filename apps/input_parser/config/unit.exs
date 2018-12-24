use Mix.Config

IO.puts("In input_parser/config/unit.exs")

config :input_parser,
  stations: Path.expand("../unit_data/stations.txt", "TransportScheduler"),
  schedule: Path.expand("../unit_data/schedule.txt", "TransportScheduler"),
  other_means: Path.expand("../unit_data/OMT.txt", "TransportScheduler"),
  local_variables:
    Path.expand("../unit_data/local_variables.txt", "TransportScheduler"),
  n_stations: 2264,
  n_schedules: 56_555,
  n_other_means: 151,
  n_loc_vars: 2264
