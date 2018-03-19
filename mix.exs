defmodule TransportScheduler.Mixfile do
  use Mix.Project

  def project do
    [
      app: :TransportScheduler,
      version: "0.1.0",
      elixir: "~> 1.6.2",
      test_coverage: [tool: ExCoveralls],
      preferred_cli_env: [coveralls: :test],
      source_url: "https://github.com/prasadtalasila/TransportScheduler",
      name: "TransportScheduler",
      start_permanent: Mix.env() == :prod,
      elixirc_paths: elixirc_paths(Mix.env()),
      deps: deps()
    ]
  end

  defp elixirc_paths(:test) do
    ["lib", "test/mocks"]
  end

  defp elixirc_paths(_), do: ["lib"]

  # Run "mix help compile.app" to learn about applications.
  def application do
    [
      extra_applications: [:logger]
    ]
  end

  # Run "mix help deps" to learn about dependencies.
  defp deps do
    [
      {:mox, "~> 0.3", only: :test},
      {:excoveralls, "~> 0.8", only: :test},
      {:credo, "~> 0.8", only: [:dev, :test], runtime: false},
      {:fsm, "~> 0.3"},
      {:logger_file_backend, "~> 0.0.10"}
    ]
  end
end
