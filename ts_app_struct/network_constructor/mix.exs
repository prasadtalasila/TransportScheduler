defmodule NetworkConstructor.Mixfile do
  use Mix.Project

  def project do
    [
      app: :network_constructor,
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
      mod: {NetworkConstructor.Application, []}
    ]
  end

  # Run "mix help deps" to learn about dependencies.
  #Change dependency path accordingly.
  defp deps do
    [
      {:input_parser,  path: "/home/bgargi/Videos/input_parser"},
      {:mox, "~> 0.3", only: :test},
      {:excoveralls, "~> 0.8", only: :test},
      {:credo, "~> 0.8", only: [:dev, :test], runtime: false},
      {:logger_file_backend, "~> 0.0.10"},
      {:fsm, "~> 0.3"}
    ]
  end
end
