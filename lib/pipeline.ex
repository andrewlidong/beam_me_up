defmodule BeamConcurrency.Pipeline do
  use GenStage
  require Logger

  def start_link(opts) do
    GenStage.start_link(__MODULE__, opts)
  end

  def init(opts) do
    producer_count = Keyword.get(opts, :producer_count, 1)
    consumer_count = Keyword.get(opts, :consumer_count, 8)
    rate = Keyword.get(opts, :rate, 1000)

    # Start producers
    producers =
      for i <- 1..producer_count do
        {:ok, pid} =
          DynamicSupervisor.start_child(
            BeamConcurrency.ProducerSupervisor,
            {BeamConcurrency.Producer, [rate: rate, name: :"producer_#{i}"]}
          )

        pid
      end

    # Start consumers
    consumers =
      for i <- 1..consumer_count do
        {:ok, pid} =
          DynamicSupervisor.start_child(
            BeamConcurrency.ConsumerSupervisor,
            {BeamConcurrency.Consumer, [name: :"consumer_#{i}"]}
          )

        pid
      end

    # Set up Flow pipeline
    Flow.from_stages(producers)
    |> Flow.partition(stages: consumer_count)
    |> Flow.into_stages(consumers)

    {:producer_consumer,
     %{
       producers: producers,
       consumers: consumers,
       start_time: System.monotonic_time(:millisecond)
     }}
  end

  def handle_events(events, _from, state) do
    # Forward events to consumers
    {:noreply, events, state}
  end
end
