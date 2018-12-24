use Mix.Config

IO.puts("In input_parser/config/integration.exs")

config :input_parser,
  stations: Path.expand("../test_data/stations.txt", "TransportScheduler"),
  schedule: Path.expand("../test_data/schedule.txt", "TransportScheduler"),
  other_means: Path.expand("../test_data/OMT.txt", "TransportScheduler"),
  local_variables:
    Path.expand("../test_data/local_variables.txt", "TransportScheduler"),
  n_stations: 6,
  n_schedules: 4,
  n_other_means: 0,
  n_loc_vars: 6

# config :input_parser,
#  stations: "../../apps/transport_scheduler/test/data/stations.txt",
#  schedule: "../../apps/transport_scheduler/test/data/schedule.txt",
#  other_means: "../../apps/transport_scheduler/test/data/OMT.txt",
#  local_variables:
#    "../../apps/transport_scheduler/test/data/local_variables.txt"
