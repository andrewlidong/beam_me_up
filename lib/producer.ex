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
      last_sent: nil,
      producer_id: Keyword.get(opts, :name, self())
    }

    {:producer, state}
  end

  @doc """
  Handles demand from consumers, generating events up to the requested amount
  while respecting the configured rate limit.
  """
  def handle_demand(demand, state) when demand > 0 do
    now = System.monotonic_time(:millisecond)
    events_to_send = calculate_events_to_send(demand, state, now)

    events =
      if events_to_send > 0 do
        for _ <- 1..events_to_send do
          %{
            id: System.unique_integer([:positive]),
            timestamp: now,
            payload: :crypto.strong_rand_bytes(32)
          }
        end
      else
        []
      end

    # Emit telemetry event
    :telemetry.execute(
      [:beam_concurrency, :producer, :events_generated],
      %{count: length(events), rate: state.rate},
      %{producer_id: state.producer_id}
    )

    # Update last_sent time only if we sent events
    new_state = if length(events) > 0, do: %{state | last_sent: now}, else: state
    {:noreply, events, new_state}
  end

  @doc """
  Handles synchronous calls to the producer.
  """
  def handle_call({:ask, demand}, _from, state) do
    now = System.monotonic_time(:millisecond)
    events_to_send = calculate_events_to_send(demand, state, now)

    events =
      if events_to_send > 0 do
        for _ <- 1..events_to_send do
          %{
            id: System.unique_integer([:positive]),
            timestamp: now,
            payload: :crypto.strong_rand_bytes(32)
          }
        end
      else
        []
      end

    # Update last_sent time only if we sent events
    new_state = if length(events) > 0, do: %{state | last_sent: now}, else: state
    {:reply, events, [], new_state}
  end

  defp calculate_events_to_send(demand, state, now) do
    case state.last_sent do
      nil ->
        # First request, allow only one event
        1

      last_sent ->
        time_since_last = now - last_sent
        # Convert to seconds and calculate allowed events
        allowed_events = floor(time_since_last * state.rate / 1000)

        # If less than one interval has passed, return 0
        if time_since_last < state.interval do
          0
        else
          min(demand, max(0, allowed_events))
        end
    end
  end
end
