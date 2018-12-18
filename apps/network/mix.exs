defmodule Network.MixProject do
  use Mix.Project

  @test_envs [:unit, :integration]

  def project do
    [
      app: :network,
      version: "0.1.0",
      build_path: "../../_build",
      config_path: "../../config/config.exs",
      deps_path: "../../deps",
      lockfile: "../../mix.lock",
      elixir: "~> 1.6",
      start_permanent: Mix.env() == :prod,
      test_coverage: [tool: ExCoveralls],
      preferred_cli_env: [coveralls: @test_envs],
      elixirc_paths: elixirc_paths(Mix.env()),
      deps: deps(),
      test_paths: test_paths(Mix.env())
    ]
  end

  defp test_paths(:integration), do: ["test/integration"]
  defp test_paths(_), do: ["test/unit"]

  # Run "mix help compile.app" to learn about applications.
  def application do
    [
      extra_applications: [:logger],
      mod: {Network.Application, []}
    ]
  end

  defp elixirc_paths(env) when env in @test_envs do
    ["lib", "test/mocks"]
  end

  defp elixirc_paths(_), do: ["lib"]

  # Run "mix help deps" to learn about dependencies.
  defp deps do
    [
      # {:input_parser, in_umbrella: :true},
      {:mox, "~> 0.3", only: @test_envs},
      # {:excoveralls, "~> 0.8", only: :test},
      {:credo, "~> 0.8", only: [:dev, :unit, :integration], runtime: false},
      {:fsm, "~> 0.3"},
      # ,
      {:logger_file_backend, "~> 0.0.10"},
      # {:dep_from_hexpm, "~> 0.3.0"},
      {:input_parser, in_umbrella: true},
      {:util, in_umbrella: true}
    ]
  end
end
