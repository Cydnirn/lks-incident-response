# Command
# docker build --platform=linux/amd64 -t loadsim:latest .

# Start from the official Golang image to build the app
FROM golang:1.24-alpine AS builder

WORKDIR /app

# Copy go.mod and go.sum files
COPY go.mod go.sum ./

# Download dependencies
RUN go mod download

# Copy the source code
COPY . .

# Build the Go app
RUN go build -o loadsim .

# Use a minimal image for running the app
FROM alpine:latest

WORKDIR /app

# Add a non-root user and group
RUN addgroup -S appgroup && adduser -S appuser -G appgroup

# Copy the built binary from the builder stage
COPY --from=builder /app/loadsim .

# Change ownership
RUN chown -R appuser:appgroup /app

# Switch to the non-root user
USER appuser

# Expose the port the app runs on
EXPOSE 8080

# Command to run the app
CMD ["./loadsim"]
