defmodule BeamConcurrency.Producer do
  @moduledoc """
  A GenStage producer that generates events at a configurable rate.

  ## Features
  - Configurable event generation rate
  - Automatic rate limiting
  - Unique event IDs
  - Random payload generation

  ## Example
      {:ok, producer} = Producer.start_link(rate: 1000)  # 1000 events per second
      events = GenStage.call(producer, {:ask, 10})  # Request 10 events
  """

  use GenStage

  @doc """
  Starts the producer with the given options.

  ## Options
    * `:rate` - The number of events to generate per second (default: 1000)
  """
  def start_link(opts) do
    GenStage.start_link(__MODULE__, opts)
  end

  @doc """
  Initializes the producer with the given rate.
  """
  def init(opts) do
    # messages per second
    rate = Keyword.get(opts, :rate, 1000)

    state = %{
      rate: rate,
      interval: 1000 / rate,
      last_sent: System.monotonic_time(:millisecond)
    }

    {:producer, state}
  end

  @doc """
  Handles demand from consumers, generating events up to the requested amount
  while respecting the configured rate limit.
  """
  def handle_demand(demand, state) when demand > 0 do
    events = generate_events(demand, state)
    {:noreply, events, state}
  end

  @doc false
  defp generate_events(demand, state) do
    now = System.monotonic_time(:millisecond)
    time_since_last = now - state.last_sent
    events_to_send = min(demand, floor(time_since_last / state.interval))

    if events_to_send > 0 do
      events =
        for _ <- 1..events_to_send do
          %{
            id: System.unique_integer([:positive]),
            timestamp: now,
            payload: :crypto.strong_rand_bytes(32)
          }
        end

      events
    else
      []
    end
  end
end
