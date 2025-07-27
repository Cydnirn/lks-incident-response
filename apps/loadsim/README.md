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

### Examples environment

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
