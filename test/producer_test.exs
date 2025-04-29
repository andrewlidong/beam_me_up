defmodule BeamConcurrency.ProducerTest do
  use ExUnit.Case, async: true
  alias BeamConcurrency.Producer

  setup do
    {:ok, producer} = Producer.start_link(rate: 1000)
    %{producer: producer}
  end

  test "generates events at configured rate", %{producer: producer} do
    # Ask for 10 events
    events = GenStage.call(producer, {:ask, 10})
    assert length(events) <= 10

    # Verify event structure
    event = hd(events)
    assert Map.has_key?(event, :id)
    assert Map.has_key?(event, :timestamp)
    assert Map.has_key?(event, :payload)
    assert byte_size(event.payload) == 32
  end

  test "respects rate limiting", %{producer: producer} do
    # First batch
    events1 = GenStage.call(producer, {:ask, 100})
    assert length(events1) > 0

    # Immediate second batch should be limited
    events2 = GenStage.call(producer, {:ask, 100})
    assert length(events2) == 0
  end
end
