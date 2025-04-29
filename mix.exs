defmodule BeamConcurrency.MixProject do
  use Mix.Project

  def project do
    [
      app: :beam_concurrency,
      version: "0.1.0",
      elixir: "~> 1.14",
      start_permanent: Mix.env() == :prod,
      deps: deps()
    ]
  end

  # Run "mix help compile.app" to learn about applications.
  def application do
    [
      extra_applications: [:logger],
      mod: {BeamConcurrency.Application, []}
    ]
  end

  # Run "mix help deps" to learn about dependencies.
  defp deps do
    [
      {:gen_stage, "~> 1.2"},
      {:flow, "~> 1.2"},
      {:telemetry, "~> 1.2"},
      {:benchee, "~> 1.1", only: :dev}
    ]
  end
end
