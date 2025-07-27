# LoadSim - Load Testing Application

A Go-based load testing application that can generate CPU and memory load for testing purposes. It includes features for simulating application crashes, graceful shutdowns, and database connectivity testing.

## Features

- **CPU Load Generation**: Generate configurable CPU load (0-80%)
- **Memory Load Generation**: Allocate specified amount of memory
- **JSON Structured Logging**: All logs are output in structured JSON format with environment field and status codes
- **Dynamic Load Management**: Incrementally increase CPU load via API endpoints
- **Crash Simulation**: Simulate application crashes for testing CrashLoopBackOff scenarios
- **Graceful Shutdown**: Simulate rolling updates and scale-down scenarios
- **Database Testing**: Test connectivity to various database engines
- **Health Checks**: Built-in health check endpoint
- **RESTful API**: HTTP API for controlling load generation

## JSON Logging

All application logs are now output in structured JSON format for better observability and log aggregation. Each log entry includes:

```json
{
  "timestamp": "2024-01-15T10:30:45.123Z",
  "level": "INFO",
  "message": "Server starting",
  "service": "loadsim",
  "environment": "production",
  "status_code": 200,
  "remote_addr": "127.0.0.1",
  "user_agent": "curl/7.68.0",
  "method": "GET",
  "path": "/status",
  "duration": "1.234ms",
  "error": "connection failed",
  "extra": {
    "cpu_load_percent": 50,
    "memory_mb": 1024
  }
}
```

### Log Levels

- **INFO**: General information messages
- **DEBUG**: Detailed debugging information
- **WARN**: Warning messages
- **ERROR**: Error messages with stack traces and status codes

### Status Codes in Error Logs

Error logs now include status codes to help with monitoring and alerting:
- **1**: Application crash/panic
- **400**: Bad request errors
- **500**: Internal server errors

## Environment Variables

| Variable | Type | Default | Description |
|----------|------|---------|-------------|
| `ENVIRONMENT` | string | `development` | Application environment (development, staging, production) |
| `PORT` | string | `8080` | Server port |
| `CPU_LOAD_PERCENT` | int | `50` | Target CPU load percentage (max 80) |
| `MEMORY_MB` | int | `1024` | Target memory load in MB |
| `DURATION_SEC` | int | `0` | Duration in seconds (0 = run until stopped) |
| `CRASH` | bool | `false` | Enable crash simulation |
| `CRASH_AFTER_TIME_MS` | int | `5000` | Time in milliseconds before auto-crash (0 = immediate) |
| `SHUTDOWN` | bool | `false` | Enable shutdown simulation |
| `SHUTDOWN_AFTER_TIME_MS` | int | `10000` | Time in milliseconds before auto-shutdown (0 = immediate) |

## Crash and Shutdown Behavior

The application supports both immediate and delayed crash/shutdown scenarios:

### Immediate Actions
- **Immediate Crash**: Set `CRASH=true` and `CRASH_AFTER_TIME_MS=0` (or don't set `CRASH_AFTER_TIME_MS`)
- **Immediate Shutdown**: Set `SHUTDOWN=true` and `SHUTDOWN_AFTER_TIME_MS=0` (or don't set `SHUTDOWN_AFTER_TIME_MS`)

### Delayed Actions
- **Delayed Crash**: Set `CRASH=true` and `CRASH_AFTER_TIME_MS=5000` (crashes after 5 seconds)
- **Delayed Shutdown**: Set `SHUTDOWN=true` and `SHUTDOWN_AFTER_TIME_MS=10000` (shutdowns after 10 seconds)

### Examples

```bash
# Immediate crash on startup
export CRASH=true
export CRASH_AFTER_TIME_MS=0

# Crash after 5 seconds
export CRASH=true
export CRASH_AFTER_TIME_MS=5000

# Immediate shutdown on startup
export SHUTDOWN=true
export SHUTDOWN_AFTER_TIME_MS=0

# Shutdown after 10 seconds
export SHUTDOWN=true
export SHUTDOWN_AFTER_TIME_MS=10000
```

## Dynamic Load Management

The application provides endpoints for dynamically managing CPU load generation:

### `/load` (GET)
Increments CPU load by 10% (configurable) up to a maximum of 70% and **starts actual CPU load generation**.

**Behavior:**
- Stops any existing load generation
- Increments the dynamic CPU load counter
- Starts new CPU load generation with the incremented percentage
- Sets `load_running` to `true`

**Response:**
```json
{
  "success": true,
  "message": "CPU load incremented from 20% to 30% and load generation started",
  "current_load": 30,
  "max_load": 70,
  "increment_step": 10
}
```

### `/load/reset` (GET)
Resets CPU load to 0% and **stops all load generation**.

**Behavior:**
- Stops any running load generation
- Resets the dynamic CPU load counter to 0
- Sets `load_running` to `false`

**Response:**
```json
{
  "success": true,
  "message": "CPU load reset from 50% to 0% and load generation stopped",
  "current_load": 0,
  "max_load": 70,
  "increment_step": 10
}
```

### Example Usage:
```bash
# First hit: Start 10% CPU load
curl http://localhost:8080/load
# Response: CPU load incremented from 0% to 10% and load generation started

# Second hit: Increase to 20% CPU load
curl http://localhost:8080/load
# Response: CPU load incremented from 10% to 20% and load generation started

# Third hit: Increase to 30% CPU load
curl http://localhost:8080/load
# Response: CPU load incremented from 20% to 30% and load generation started

# Reset: Stop all load generation
curl http://localhost:8080/load/reset
# Response: CPU load reset from 30% to 0% and load generation stopped
```

## API Endpoints

| Endpoint | Method | Description |
|----------|--------|-------------|
| `/` | GET | HTML dashboard with controls |
| `/status` | GET | Get current load status (JSON) |
| `/health` | GET | Health check |
| `/start` | POST | Start load generation |
| `/stop` | POST | Stop load generation |
| `/setting` | POST | Update load settings |
| `/database` | POST | Test database connection |
| `/error` | GET | Simulate error (HTTP 500) |
| `/crash` | GET | Manual crash trigger |
| `/shutdown` | GET | Manual graceful shutdown |
| `/load` | GET | Increment dynamic CPU load |
| `/load/reset` | GET | Reset dynamic CPU load to 0 |

## Database Testing

Test connectivity to various database engines:

```bash
curl -X POST http://localhost:8080/database \
  -H "Content-Type: application/json" \
  -d '{
    "engine": "mysql",
    "connection_string": "user:password@tcp(localhost:3306)/dbname"
  }'
```

Supported engines:
- **MySQL**: `mysql://user:password@host:port/database`
- **PostgreSQL**: `postgres://user:password@host:port/database`
- **SQLite**: `file:path/to/database.db`
- **DynamoDB**: AWS region (e.g., `us-east-1`)

## Building and Running

### Local Development

```bash
cd apps/loadsim
go mod tidy
go run .
```

### Docker

```bash
docker build -t loadsim .
docker run -p 8080:8080 \
  -e ENVIRONMENT=production \
  -e CRASH=true \
  -e CRASH_AFTER_TIME_MS=5000 \
  loadsim
```

### Kubernetes

```yaml
apiVersion: apps/v1
kind: Deployment
metadata:
  name: loadsim
spec:
  replicas: 1
  selector:
    matchLabels:
      app: loadsim
  template:
    metadata:
      labels:
        app: loadsim
    spec:
      containers:
      - name: loadsim
        image: loadsim:latest
        ports:
        - containerPort: 8080
        env:
        - name: ENVIRONMENT
          value: "production"
        - name: CRASH
          value: "true"
        - name: CRASH_AFTER_TIME_MS
          value: "5000"
```

## Example Usage

### Start with 50% CPU and 1GB memory load

```bash
curl -X POST http://localhost:8080/start
```

### Update settings

```bash
curl -X POST http://localhost:8080/setting \
  -H "Content-Type: application/json" \
  -d '{
    "cpu_load_percent": 30,
    "memory_mb": 512,
    "duration_sec": 60
  }'
```

### Check status

```bash
curl http://localhost:8080/status
```

### Increment dynamic load

```bash
curl http://localhost:8080/load
```

### Reset dynamic load

```bash
curl http://localhost:8080/load/reset
```

### Test database connection

```bash
curl -X POST http://localhost:8080/database \
  -H "Content-Type: application/json" \
  -d '{
    "engine": "postgres",
    "connection_string": "postgres://user:pass@localhost:5432/testdb"
  }'
```

## Log Examples

### Application Startup (Production Environment)
```json
{"timestamp":"2024-01-15T10:30:45.123Z","level":"INFO","message":"Server starting","service":"loadsim","environment":"production","extra":{"port":"8080"}}
```

### Load Generation Start
```json
{"timestamp":"2024-01-15T10:30:46.456Z","level":"INFO","message":"Load started","service":"loadsim","environment":"production","remote_addr":"127.0.0.1","user_agent":"curl/7.68.0","extra":{"cpu_load_percent":50,"memory_mb":1024}}
```

### Immediate Crash (Status Code 1)
```json
{"timestamp":"2024-01-15T10:30:45.789Z","level":"ERROR","message":"Immediate crash triggered","service":"loadsim","environment":"production","status_code":1,"error":"CRASH=true with no delay specified"}
```

### Delayed Crash (Status Code 1)
```json
{"timestamp":"2024-01-15T10:30:50.789Z","level":"ERROR","message":"Delayed crash triggered","service":"loadsim","environment":"production","status_code":1,"error":"CRASH=true with 5000ms delay"}
```

### Dynamic Load Increment
```json
{"timestamp":"2024-01-15T10:30:47.123Z","level":"INFO","message":"Dynamic load incremented","service":"loadsim","environment":"production","remote_addr":"127.0.0.1","user_agent":"curl/7.68.0","extra":{"old_load":20,"new_load":30,"increment_step":10,"max_load":70}}
```

### Database Connection Test
```json
{"timestamp":"2024-01-15T10:30:47.012Z","level":"INFO","message":"Database connection test successful","service":"loadsim","environment":"production","remote_addr":"127.0.0.1","user_agent":"curl/7.68.0","extra":{"engine":"mysql","duration":"45.67ms","duration_ms":45}}
```

## Troubleshooting

### Crash not working
- Ensure both `CRASH=true` and `CRASH_AFTER_TIME_MS=<value>` are set correctly
- Check logs for crash timer initialization
- Verify the application has proper permissions
- For immediate crash, set `CRASH_AFTER_TIME_MS=0`

### Memory allocation issues
- Reduce `MEMORY_MB` value if system runs out of memory
- Monitor system memory usage during load generation

### Database connection failures
- Verify connection strings are correct
- Check network connectivity to database servers
- Ensure proper credentials and permissions

### Environment not showing in logs
- Set `ENVIRONMENT` environment variable to desired value (development, staging, production)
- Check that the environment variable is properly passed to the container

### Dynamic load not working
- Check that the `/load` endpoint is accessible
- Verify that the current load hasn't reached the maximum (70%)
- Use `/load/reset` to reset the load to 0% if needed
