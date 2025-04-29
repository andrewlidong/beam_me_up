defmodule BeamConcurrency.Application do
  # See https://hexdocs.pm/elixir/Application.html
  # for more information on OTP Applications
  @moduledoc false

  use Application

  @impl true
  def start(_type, _args) do
    children = [
      # Start the DynamicSupervisor for producers
      {DynamicSupervisor, name: BeamConcurrency.ProducerSupervisor, strategy: :one_for_one},
      # Start the DynamicSupervisor for consumers
      {DynamicSupervisor, name: BeamConcurrency.ConsumerSupervisor, strategy: :one_for_one},
      # Start the Pipeline
      {BeamConcurrency.Pipeline, [producer_count: 1, consumer_count: 8, rate: 1000]},
      # Start the Benchmark
      {BeamConcurrency.Benchmark, []}
    ]

    # See https://hexdocs.pm/elixir/Supervisor.html
    # for other strategies and supported options
    opts = [strategy: :one_for_one, name: BeamConcurrency.Supervisor]
    Supervisor.start_link(children, opts)
  end
end
