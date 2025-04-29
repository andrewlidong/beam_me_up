FROM elixir:1.14.5-alpine AS builder

# Install build dependencies
RUN apk add --no-cache build-base git

# Set working directory
WORKDIR /app

# Install hex and rebar
RUN mix local.hex --force && \
  mix local.rebar --force

# Copy mix files
COPY mix.exs mix.lock ./

# Install dependencies
RUN mix deps.get --only prod

# Copy source code
COPY . .

# Compile application
RUN mix compile

# Build release
RUN mix release

# Create a new stage for the runtime
FROM alpine:3.16

# Install runtime dependencies
RUN apk add --no-cache openssl ncurses-libs

# Set working directory
WORKDIR /app

# Copy release from builder
COPY --from=builder /app/_build/prod/rel/beam_concurrency ./

# Set environment variables
ENV MIX_ENV=prod
ENV PORT=4000

# Expose port
EXPOSE 4000

# Start the application
CMD ["bin/beam_concurrency", "start"]