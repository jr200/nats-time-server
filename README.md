# nats-time-server

Publishes UTC time to a NATS subject at some cadence.

### Features
- **Tick speed**: run time faster/slower via `clock_increment`
- **Tick cadence**: set `tick_frequency`
- **Start point**: set `clock_start_utc`
- **No-future guard**: `allow_future_time`

### Quick start
```bash
# 1) Install
poetry install

# 2) Ensure NATS is running (adjust creds in config if needed)
#    Default server: nats://127.0.0.1:4222
#    Default creds:  secrets/app.creds

# 3) Run
poetry run start_api
```

### NATS
- **Subject**: `{instance_id}.time-server` (from `service.instance_id`, e.g. `dev01.time-server`)
- **Payload**: `{"type":"epoch_ms","data": <epoch_ms>}`

Subscribe example:
```bash
nats sub dev01.time-server --server nats://127.0.0.1:4222
```

### Configuration
Edit `src/nats_time_server/config.yaml`:
- **nats**: servers, creds, client options
- **service.instance_id**: prefixes the subject
- **app.clock_start_utc**: ISO8601 (e.g. `2025-07-24T01:20:00Z`)
- **app.clock_increment**: duration (`ms|s|m|h`)
- **app.tick_frequency**: publish interval (`ms|s|m|h`)
- **app.allow_future_time**: if false, never publish a time past the server's local time

