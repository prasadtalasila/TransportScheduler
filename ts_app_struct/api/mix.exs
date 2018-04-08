defmodule API.Mixfile do
  use Mix.Project

  def project do
    [
      app: :api,
      version: "0.1.0",
      elixir: "~> 1.6.2",
      start_permanent: Mix.env == :prod,
      deps: deps()
    ]
  end

  # Run "mix help compile.app" to learn about applications.
  def application do
    [
      extra_applications: [:logger],
      mod: {API.Application, []}
    ]
  end

  # Run "mix help deps" to learn about dependencies.
  #Change dependency path accordingly.
  defp deps do
    [
      {:network_constructor,  path: "/home/bgargi/Videos/network_constructor"},
      {:mox, "~> 0.3", only: :test},
      {:credo, "~> 0.8", only: [:dev, :test], runtime: false},
      {:logger_file_backend, "~> 0.0.10"},
      {:excoveralls, "~> 0.8", only: :test},
      {:maru, "~> 0.11"},
      {:httpoison,  "~> 0.11.0"}

    ]
  end
end
