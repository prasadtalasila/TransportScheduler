defmodule Api.Mixfile do
  use Mix.Project

  def project do
    [
      app: :api,
      version: "0.1.0",
      build_path: "../../_build",
      config_path: "../../config/config.exs",
      deps_path: "../../deps",
      lockfile: "../../mix.lock",
      elixir: "~> 1.6",
      test_coverage: [tool: ExCoveralls],
      preferred_cli_env: [coveralls: :test],
      start_permanent: Mix.env() == :prod,
      deps: deps()
    ]
  end

  # Run "mix help compile.app" to learn about applications.
  def application do
    [
      extra_applications: [:logger],
      mod: {Api.Application, []}
    ]
  end

  # Run "mix help deps" to learn about dependencies.
  defp deps do
    [
      # {:network, in_umbrella: :true},
      {:mox, "~> 0.3", only: :test},
      {:credo, "~> 0.8", only: [:dev, :test], runtime: false},
      {:logger_file_backend, "~> 0.0.10"},
      {:excoveralls, "~> 0.8", only: :test},
      {:maru, "~> 0.11"},
      {:httpoison, "~> 0.11.0"}
    ]
  end
end
