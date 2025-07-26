# IRS Backend API

A Go backend application built with Fiber framework to provide incident ticket data from DynamoDB for the IRS Frontend application.

## Features

- RESTful API endpoints for incident tickets
- DynamoDB integration with AWS SDK v2
- CORS support for frontend integration
- Health check endpoint
- Comprehensive filtering and search capabilities
- AWS credentials support including session tokens

## Prerequisites

- Go 1.21 or higher
- AWS credentials configured
- DynamoDB table named `insident` with appropriate GSIs

## Setup

1. **Install dependencies:**
   ```bash
   go mod tidy
   ```

2. **Export this AWS credentials to you OS Env variables or create .env:**
   ```bash
   export AWS_REGION=us-east-1 # Optional
   export AWS_ACCESS_KEY_ID=your_access_key # Required
   export AWS_SECRET_ACCESS_KEY=your_secret_key # Required
   export AWS_SESSION_TOKEN=your_session_token # Required
   export DYNAMODB_TABLE_NAME=insident # Optional
   export PORT=8080 # Optional
   export HOST=0.0.0.0 # Optional
   ```

## Running the Application

```bash
go run main.go
```

### Build the Application
```bash
go build -o irs-be cmd/main.go
```

The server will start on `http://localhost:8080` (or the port specified in your config).

## Docker Build
```bash
docker build \
  --platform=linux/amd64 \
  --no-cache \
  -t irsbe \
  -f docker/Dockerfile \
  --build-arg VITE_AWS_REGION=us-east-1 \
  --build-arg VITE_AWS_ACCESS_KEY_ID=your_aws_key_id. \
  --build-arg VITE_AWS_SECRET_ACCESS_KEY=your_aws_secret \
  --build-arg VITE_AWS_SESSION_TOKEN=you_aws_token
  .

## API Endpoints

### Health Check
- `GET /health` - Check if the service is healthy

### Tickets
- `GET /api/tickets` - Get all tickets
- `GET /api/tickets/:id` - Get ticket by ID
- `GET /api/tickets/status/:status` - Get tickets by status
- `GET /api/tickets/severity/:severity` - Get tickets by severity
- `GET /api/tickets/incident-type/:incidentType` - Get tickets by incident type
- `GET /api/tickets/search?q=query` - Search tickets
- `GET /api/tickets/filter?severity=critical&category=kubernetes` - Filter tickets

## Development

### Project Structure
```
irs-be/
├── main.go              # Application entry point
├── go.mod               # Go module file
├── config.env           # Environment configuration
├── models/
│   └── ticket.go        # Data models
├── services/
│   └── dynamodb.go      # DynamoDB service
└── handlers/
    └── ticket.go        # HTTP handlers
```

### Building for Production
```bash
go build -o irs-be cmd/main.go
```
