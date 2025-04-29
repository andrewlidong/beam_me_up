defmodule BeamConcurrency.Telemetry do
  @moduledoc """
  Telemetry integration for monitoring the system's performance and behavior.
  """

  def attach_handlers do
    :telemetry.attach_many(
      "beam-concurrency-handler",
      [
        [:beam_concurrency, :producer, :events_generated],
        [:beam_concurrency, :consumer, :events_processed],
        [:beam_concurrency, :consumer, :events_failed],
        [:beam_concurrency, :pipeline, :latency]
      ],
      &handle_event/4,
      nil
    )
  end

  def handle_event(
        [:beam_concurrency, :producer, :events_generated],
        measurements,
        metadata,
        _config
      ) do
    Logger.info("""
    Producer Telemetry:
    - Events Generated: #{measurements.count}
    - Rate: #{measurements.rate} events/sec
    - Producer: #{inspect(metadata.producer_id)}
    """)
  end

  def handle_event(
        [:beam_concurrency, :consumer, :events_processed],
        measurements,
        metadata,
        _config
      ) do
    Logger.info("""
    Consumer Telemetry:
    - Events Processed: #{measurements.count}
    - Processing Time: #{measurements.processing_time}ms
    - Consumer: #{inspect(metadata.consumer_id)}
    """)
  end

  def handle_event(
        [:beam_concurrency, :consumer, :events_failed],
        measurements,
        metadata,
        _config
      ) do
    Logger.warning("""
    Consumer Failure:
    - Failed Events: #{measurements.count}
    - Error: #{inspect(metadata.error)}
    - Consumer: #{inspect(metadata.consumer_id)}
    """)
  end

  def handle_event([:beam_concurrency, :pipeline, :latency], measurements, _metadata, _config) do
    Logger.info("""
    Pipeline Latency:
    - Average: #{measurements.avg}ms
    - P95: #{measurements.p95}ms
    - P99: #{measurements.p99}ms
    """)
  end
end
