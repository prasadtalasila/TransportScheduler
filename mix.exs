defmodule TransportScheduler.Mixfile do
  use Mix.Project

  def project do
    [
      app: :TransportScheduler,
      version: "0.1.0",
      elixir: "~> 1.5.3",
      test_coverage: [tool: ExCoveralls],
      preferred_cli_env: [coveralls: :test],
      source_url: "https://github.com/prasadtalasila/TransportScheduler",
      name: "TransportScheduler",
      start_permanent: Mix.env == :prod,
      deps: deps()
    ]
  end

  # Run "mix help compile.app" to learn about applications.
  def application do
    [
      extra_applications: [:logger]
    ]
  end

  # Run "mix help deps" to learn about dependencies.
  defp deps do
    [
      {:mox, "~> 0.3.1", only: :test},
      {:excoveralls, "~> 0.7", only: :test},
      {:credo, "~> 0.8", only: [:dev, :test], runtime: false},
      {:fsm, "~> 0.3.0"}
      #{:workex, "~> 0.10.0"}
      # {:dep_from_hexpm, "~> 0.3.0"},
      # {:dep_from_git, git: "https://github.com/elixir-lang/my_dep.git", tag: "0.1.0"},
    ]
  end
end
