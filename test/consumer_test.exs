defmodule BeamConcurrency.ConsumerTest do
  use ExUnit.Case, async: true
  alias BeamConcurrency.Consumer

  setup do
    {:ok, consumer} = Consumer.start_link(failure_rate: 0.0)
    %{consumer: consumer}
  end

  test "processes events successfully", %{consumer: consumer} do
    events = [
      %{id: 1, payload: "test1"},
      %{id: 2, payload: "test2"}
    ]

    state = %{
      processed: 0,
      failed: 0,
      failure_rate: 0.0,
      consumer_id: self(),
      processing_time: 10
    }

    {:noreply, [], state} = Consumer.handle_events(events, self(), state)
    assert state.processed == 2
    assert state.failed == 0
  end

  test "handles failures gracefully", %{consumer: consumer} do
    events = [%{id: 1, payload: "test"}]

    state = %{
      processed: 0,
      failed: 0,
      failure_rate: 1.0,
      consumer_id: self(),
      processing_time: 10
    }

    {:noreply, [], state} = Consumer.handle_events(events, self(), state)
    assert state.failed == 1
    assert state.processed == 0
  end

  test "returns metrics", %{consumer: consumer} do
    state = %{
      processed: 42,
      failed: 7,
      failure_rate: 0.1,
      consumer_id: self(),
      processing_time: 10
    }

    {:reply, metrics, [], ^state} = Consumer.handle_call(:metrics, self(), state)
    assert metrics.processed == 42
    assert metrics.failed == 7
  end
end
