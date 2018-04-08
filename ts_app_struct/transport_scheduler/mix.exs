defmodule TransportScheduler.Mixfile do
  use Mix.Project

  def project do
    [
      app: :transport_scheduler,
      version: "0.1.0",
      elixir: "~> 1.6.2",
      test_coverage: [tool: ExCoveralls],
      start_permanent: Mix.env == :prod,
      elixirc_paths: elixirc_paths(Mix.env()),
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
  #Change dependency path accordingly.
  defp deps do
    [

      {:input_parser,  path: "/home/bgargi/Videos/input_parser"},
      {:network_constructor,  path: "/home/bgargi/Videos/network_constructor"},
      {:api,  path: "/home/bgargi/Videos/api"}

    ]
  end
end
