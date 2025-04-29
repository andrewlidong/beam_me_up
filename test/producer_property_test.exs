defmodule BeamConcurrency.ProducerPropertyTest do
  use ExUnit.Case
  use ExUnitProperties
  alias BeamConcurrency.Producer

  property "generates valid events" do
    check all(
            rate <- StreamData.positive_integer(),
            demand <- StreamData.positive_integer()
          ) do
      {:ok, producer} = Producer.start_link(rate: rate)
      events = GenStage.call(producer, {:ask, demand})

      assert is_list(events)

      assert Enum.all?(events, fn event ->
               is_integer(event.id) and
                 is_integer(event.timestamp) and
                 is_binary(event.payload) and
                 byte_size(event.payload) == 32
             end)
    end
  end

  property "respects rate limiting over time" do
    check all(
            rate <- StreamData.integer(1..1000),
            demands <- StreamData.list_of(StreamData.positive_integer(), length: 3)
          ) do
      {:ok, producer} = Producer.start_link(rate: rate)

      # First demand should get events
      events1 = GenStage.call(producer, {:ask, Enum.at(demands, 0)})
      assert not Enum.empty?(events1)

      # Immediate second demand should be limited
      events2 = GenStage.call(producer, {:ask, Enum.at(demands, 1)})
      assert events2 == []

      # Wait for slightly more than one interval
      interval = ceil(1000 / rate)
      Process.sleep(interval + 10)
      events3 = GenStage.call(producer, {:ask, Enum.at(demands, 2)})
      assert not Enum.empty?(events3)
    end
  end
end
