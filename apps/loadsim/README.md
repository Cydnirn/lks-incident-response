# loadsim

This is a Go application to simulate CPU and memory load for testing resource usage and autoscaling behavior. This 

## Features

- Simulate CPU load up to 80% across all CPU cores.
- Simulate memory load in MB.
- Control load duration or run continuously until stopped.
- HTTP API endpoints to start, stop, check status, update settings.
- Health check endpoint.
- Database connection check for MySQL, PostgreSQL, SQLite, and DynamoDB.
- Automatic crash and shutdown simulation for testing CrashLoopBackOff and rolling updates.
- Usage instructions available at the root endpoint `/`.

## Building and Running

### Running without Docker

Make sure you have Go installed (version 1.20 or later).

Clone or copy the source code, then run:

```bash
go run main.go
```

Or build the binary and run:

```bash
go build -o loadsim main.go
./loadsim
```

The app listens on port 8080 by default.

### Building and Running with Docker

#### Build the Docker image

```bash
docker build -t loadsim .
```

#### Run the Docker container

```bash
docker run -p 8080:8080 \
  -e CPU_LOAD_PERCENT=50 \
  -e MEMORY_MB=1536 \
  -e DURATION_SEC=0 \
  -e CRASH=false \
  -e CRASH_AFTER_TIME_MS=5000 \
  -e SHUTDOWN=false \
  -e SHUTDOWN_AFTER_TIME_MS=10000 \
  loadsim
```

## Environment Variables

- `CPU_LOAD_PERCENT`: Target CPU load percentage (max 80).
- `MEMORY_MB`: Target memory load in MB.
- `DURATION_SEC`: Duration in seconds to run the load. 0 means run until stopped.
- `PORT`: Server port (default: 8080).
- `CRASH`: Boolean to enable automatic crash simulation (default: false).
- `CRASH_AFTER_TIME_MS`: Time in milliseconds before auto-crash (default: 5000ms).
- `SHUTDOWN`: Boolean to enable automatic shutdown simulation (default: false).
- `SHUTDOWN_AFTER_TIME_MS`: Time in milliseconds before auto-shutdown (default: 10000ms).

## API Endpoints

See the usage instructions by accessing the root endpoint `/` after starting the app.

## Example Usage with curl

Start load:

```bash
curl -X POST http://localhost:8080/start
```

Stop load:

```bash
curl -X POST http://localhost:8080/stop
```

Check status:

```bash
curl http://localhost:8080/status
```

Update settings:

```bash
curl -X POST http://localhost:8080/setting -H "Content-Type: application/json" -d '{"cpu_load_percent":40,"memory_mb":2048,"duration_sec":60}'
```

Health check:

```bash
curl http://localhost:8080/health
```

Check database connection:

```bash
curl -X POST http://localhost:8080/database -H "Content-Type: application/json" -d '{"engine":"mysql","connection_string":"user:password@tcp(localhost:3306)/dbname"}'
```

## License

MIT License
