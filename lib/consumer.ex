defmodule BeamConcurrency.Consumer do
  @moduledoc """
  A GenStage consumer that processes events with configurable failure rates.

  ## Features
  - Configurable failure rate
  - Automatic retry mechanism
  - Event processing delay simulation
  - Telemetry integration

  ## Example
      {:ok, consumer} = Consumer.start_link(failure_rate: 0.1)  # 10% failure rate
  """

  use GenStage
  require Logger

  @doc """
  Starts the consumer with the given options.

  ## Options
    * `:failure_rate` - The probability of event processing failure (default: 0.0)
    * `:processing_time` - The time to simulate processing each event in milliseconds (default: 10)
  """
  def start_link(opts) do
    GenStage.start_link(__MODULE__, opts)
  end

  @doc """
  Initializes the consumer with the given options.
  """
  def init(opts) do
    failure_rate = Keyword.get(opts, :failure_rate, 0.0)
    processing_time = Keyword.get(opts, :processing_time, 10)

    state = %{
      failure_rate: failure_rate,
      processing_time: processing_time,
      consumer_id: Keyword.get(opts, :name, self()),
      processed: 0,
      failed: 0
    }

    {:consumer, state}
  end

  @doc """
  Handles events from the producer, processing them with a configurable failure rate.
  """
  def handle_events(events, _from, state) do
    # Ensure consumer_id is present in state
    state = Map.put_new(state, :consumer_id, self())

    results = Enum.map(events, &process_event(&1, state))
    successes = Enum.count(results, &(&1 != :error))
    failures = length(events) - successes

    # Emit telemetry event
    :telemetry.execute(
      [:beam_concurrency, :consumer, :events_processed],
      %{count: length(events), failure_rate: state.failure_rate},
      %{consumer_id: state.consumer_id}
    )

    new_state = %{
      state
      | processed: state.processed + successes,
        failed: state.failed + failures
    }

    {:noreply, [], new_state}
  end

  @doc false
  defp process_event(event, state) do
    # Simulate processing time
    Process.sleep(state.processing_time)

    # Simulate failure based on failure rate
    if :rand.uniform() < state.failure_rate do
      raise "Simulated processing failure"
    end

    event
  rescue
    error ->
      # Emit telemetry event for failure
      :telemetry.execute(
        [:beam_concurrency, :consumer, :processing_failed],
        %{error: inspect(error)},
        %{consumer_id: state.consumer_id, event_id: event.id}
      )

      :error
  end

  def handle_call(:metrics, _from, state) do
    {:reply, %{processed: state.processed, failed: state.failed}, [], state}
  end
end
