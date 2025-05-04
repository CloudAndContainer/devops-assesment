# Build stage
FROM golang:1.21-alpine3.19 AS builder

# Install required build tools
RUN apk add --no-cache git make

WORKDIR /app

# Copy go mod files first for better caching
COPY go.mod go.sum ./
RUN go mod download

# Copy all source code
COPY . .

# Build the application
RUN CGO_ENABLED=0 GOOS=linux GOARCH=amd64 go build -a -installsuffix cgo -ldflags="-w -s" -o transaction-api .

# Final stage
FROM alpine:3.19

# Add ca-certificates for HTTPS requests and postgresql-client for database connectivity
RUN apk --no-cache add ca-certificates postgresql-client

# Create non-root user
RUN addgroup -S appgroup && adduser -S appuser -G appgroup

WORKDIR /app

# Copy the binary from builder
COPY --from=builder /app/transaction-api .

# Copy all required directories
COPY --from=builder /app/config/ ./config/
COPY --from=builder /app/db/ ./db/

# Copy wait script and entrypoint
COPY docker-entrypoint.sh .
RUN chmod +x docker-entrypoint.sh

# Use non-root user - but need to change ownership of files first
RUN chown -R appuser:appgroup /app
USER appuser

# Expose application port
EXPOSE 8080

# Health check
HEALTHCHECK --interval=30s --timeout=3s --start-period=5s --retries=3 \
  CMD wget --no-verbose --tries=1 --spider http://localhost:8080/health || exit 1

# Start application using entrypoint script
ENTRYPOINT ["/app/docker-entrypoint.sh"]