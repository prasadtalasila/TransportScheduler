defmodule TransportScheduler.MixProject do
  use Mix.Project

  @test_envs [:unit, :integration]

  def project do
    [
      apps_path: "apps",
      start_permanent: Mix.env() == :prod,
      test_coverage: [tool: ExCoveralls],
      preferred_cli_env: [coveralls: @test_envs],
      deps: deps()
    ]
  end

  # Dependencies listed here are available only for this
  # project and cannot be accessed from applications inside
  # the apps folder.
  #
  # Run "mix help deps" for examples and options.
  defp deps do
    [
      {:excoveralls, "~> 0.8", only: @test_envs},
      {:credo, "~> 0.10.0", only: [:dev, :unit, :integration], runtime: false}
    ]
  end
end
