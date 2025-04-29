defmodule BeamConcurrency.Benchmark do
  use GenServer
  require Logger

  def start_link(opts) do
    GenServer.start_link(__MODULE__, opts, name: __MODULE__)
  end

  def init(_opts) do
    schedule_measurement()
    {:ok, %{start_time: System.monotonic_time(:millisecond), measurements: []}}
  end

  def handle_info(:measure, state) do
    # Get metrics from all consumers
    metrics =
      Supervisor.which_children(BeamConcurrency.ConsumerSupervisor)
      |> Enum.map(fn {_, pid, _, _} ->
        GenServer.call(pid, :metrics)
      end)

    total_processed = Enum.sum(Enum.map(metrics, & &1.processed))
    total_failed = Enum.sum(Enum.map(metrics, & &1.failed))
    elapsed = (System.monotonic_time(:millisecond) - state.start_time) / 1000

    throughput = total_processed / elapsed
    failure_rate = total_failed / (total_processed + total_failed)

    Logger.info("""
    Benchmark Results:
    - Throughput: #{round(throughput)} events/sec
    - Total Processed: #{total_processed}
    - Total Failed: #{total_failed}
    - Failure Rate: #{Float.round(failure_rate * 100, 2)}%
    - Elapsed Time: #{round(elapsed)}s
    """)

    schedule_measurement()
    {:noreply, state}
  end

  defp schedule_measurement do
    # Measure every 5 seconds
    Process.send_after(self(), :measure, 5000)
  end
end
