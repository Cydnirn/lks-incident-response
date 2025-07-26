# Build stage
FROM golang:1.21-alpine AS builder

# Set working directory
WORKDIR /app

# Copy go mod files
COPY go.mod go.sum ./

# Download dependencies
RUN go mod download

# Copy source code
COPY . .

# Build the application
RUN go build -o irs-be cmd/main.go

# Final stage
FROM alpine:latest

# Install ca-certificates for HTTPS requests
RUN apk --no-cache add ca-certificates

# Set working directory
WORKDIR /app

# Add a non-root user and group
RUN addgroup -S appgroup && adduser -S appuser -G appgroup

# Copy the binary from builder stage
COPY --from=builder /app/irs-be .

# Change ownership
RUN chown -R appuser:appgroup /app

# Switch to the non-root user
USER appuser

# Expose port
EXPOSE 8080

# Run the application
CMD ["./irs-be"] 