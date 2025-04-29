defmodule BeamConcurrency.ConsumerTest do
  use ExUnit.Case, async: true
  alias BeamConcurrency.Consumer

  setup do
    {:ok, consumer} = Consumer.start_link(failure_rate: 0.0)
    %{consumer: consumer}
  end

  test "processes events successfully", %{consumer: consumer} do
    events = [
      %{
        id: 1,
        timestamp: System.monotonic_time(:millisecond),
        payload: :crypto.strong_rand_bytes(32)
      },
      %{
        id: 2,
        timestamp: System.monotonic_time(:millisecond),
        payload: :crypto.strong_rand_bytes(32)
      }
    ]

    {:noreply, [], state} =
      Consumer.handle_events(events, self(), %{processed: 0, failed: 0, failure_rate: 0.0})

    assert state.processed == 2
    assert state.failed == 0
  end

  test "handles failures gracefully", %{consumer: consumer} do
    events = [
      %{
        id: 1,
        timestamp: System.monotonic_time(:millisecond),
        payload: :crypto.strong_rand_bytes(32)
      }
    ]

    {:noreply, [], state} =
      Consumer.handle_events(events, self(), %{processed: 0, failed: 0, failure_rate: 1.0})

    assert state.processed == 0
    assert state.failed == 1
  end

  test "returns metrics", %{consumer: consumer} do
    state = %{processed: 100, failed: 5, failure_rate: 0.0}
    {:reply, metrics, [], _} = Consumer.handle_call(:metrics, self(), state)
    assert metrics.processed == 100
    assert metrics.failed == 5
  end
end
