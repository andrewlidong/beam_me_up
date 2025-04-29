# BEAM Me Up

A high-performance, fault-tolerant event processing system built on the BEAM virtual machine, implementing actor-based message passing, automatic back-pressure, and robust fault tolerance.

## Features

- **High Throughput Processing**: Optimized event processing pipeline with configurable throughput
- **Automatic Back-pressure**: Intelligent demand signaling via `GenStage` to prevent system overload
- **Fault Tolerance**: Distributed supervision tree with automatic process recovery
- **Real-time Telemetry**: Comprehensive metrics collection and monitoring
- **Property-based Testing**: Rigorous test suite using StreamData for system reliability
- **CI/CD Pipeline**: Automated testing and deployment via GitHub Actions
- **Containerized Deployment**: Production-ready Docker support
- **Comprehensive Documentation**: Detailed API and system documentation

## Architecture

The system consists of three main components:

1. **Producers**: High-performance event generators with configurable throughput
2. **Flow Pipeline**: Distributed work distribution system using `Flow`
3. **Consumers**: Resilient event processors with built-in fault handling and metrics

```
┌────────┐   produce()   ┌───────────────┐   forward()   ┌───────────┐
│Producer│ ───────────▶ │ GenStageFlow  │ ───────────▶ │ Consumer  │
└────────┘               └───────────────┘               └───────────┘
     ▲       failure       ▲         supervise        ▲
     │◀───────────────────▶│◀───────────────────────▶│
  Supervisor                           Supervisor Tree
```

## Getting Started

### Local Development

1. Install dependencies:
   ```bash
   mix deps.get
   ```

2. Start the system:
   ```bash
   iex -S mix
   ```

3. Monitor system performance via telemetry:
   - Throughput (events/sec)
   - Processing latency
   - Failure rates
   - System metrics

### Production Deployment

1. Build the Docker image:
   ```bash
   docker build -t beam_concurrency .
   ```

2. Deploy the container:
   ```bash
   docker run -p 4000:4000 beam_concurrency
   ```

## Testing

The system includes a comprehensive test suite:

- Unit tests
- Property-based tests
- Integration tests

Run the test suite:
```bash
mix test
```

Run property-based tests:
```bash
mix test test/producer_property_test.exs
```

## Documentation

Generate system documentation:
```bash
mix docs
```

View documentation:
```bash
open doc/index.html
```