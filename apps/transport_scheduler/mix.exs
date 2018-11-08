defmodule TransportScheduler.Mixfile do
  use Mix.Project

  def project do
    [
      app: :transport_scheduler,
      version: "0.1.0",
      build_path: "../../_build",
      config_path: "../../config/config.exs",
      deps_path: "../../deps",
      lockfile: "../../mix.lock",
      elixir: "~> 1.6",
      test_coverage: [tool: ExCoveralls],
      elixirc_paths: elixirc_paths(Mix.env()),
      start_permanent: Mix.env() == :prod,
      deps: deps()
    ]
  end

  # Run "mix help compile.app" to learn about applications.
  def application do
    [
      extra_applications: [:logger],
      mod: {TransportScheduler.Application, []}
    ]
  end

  defp elixirc_paths(:test) do
    ["lib", "test/mocks"]
  end

  defp elixirc_paths(_), do: ["lib"]
  # Run "mix help deps" to learn about dependencies.
  defp deps do
    [
      # {:network, in_umbrella: :true},
      # {:api, in_umbrella: :true},
      # {:input_parser, in_umbrella: :true}
      # {:input_parser, in_umbrella: :true}
      # {:dep_from_hexpm, "~> 0.3.0"},
      {:input_parser, in_umbrella: true},
      {:network, in_umbrella: true}
    ]
  end
end
