defmodule BeamConcurrency.Consumer do
  use GenStage
  require Logger

  def start_link(opts) do
    GenStage.start_link(__MODULE__, opts)
  end

  def init(opts) do
    failure_rate = Keyword.get(opts, :failure_rate, 0.01)

    state = %{
      failure_rate: failure_rate,
      processed: 0,
      failed: 0
    }

    {:consumer, state}
  end

  def handle_events(events, _from, state) do
    processed =
      Enum.reduce(events, 0, fn event, acc ->
        try do
          # Simulate CPU-bound work
          :crypto.hash(:sha256, event.payload)
          # Random failure injection
          if :rand.uniform() < state.failure_rate do
            raise "Simulated failure"
          end

          acc + 1
        rescue
          error ->
            Logger.error("Consumer failed processing event #{event.id}: #{inspect(error)}")
            state.failed + 1
        end
      end)

    new_state = %{
      state
      | processed: state.processed + processed,
        failed: state.failed + (length(events) - processed)
    }

    {:noreply, [], new_state}
  end

  def handle_call(:metrics, _from, state) do
    {:reply, %{processed: state.processed, failed: state.failed}, [], state}
  end
end
