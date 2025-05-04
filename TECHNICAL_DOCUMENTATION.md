# Transaction API - Production Deployment

## Description

This repository contains a simple bank transaction API, developed in Go using the following technologies:

- **Gin**: Web framework
- **Viper**: Configuration management
- **sqlc**: SQL code generator
- **goose**: Database migrations

The application stores data in a PostgreSQL database and supports schema migration on startup.

## Project Structure

```
.
├── Dockerfile                  # Multi-stage Docker build
├── docker-compose.yml          # Production docker-compose
├── docker-entrypoint.sh        # Entry script with PostgreSQL wait
├── .dockerignore               # Docker build exclusions
├── .github/
│   └── workflows/
│       └── ci-cd.yml           # GitHub Actions CI/CD workflow
├── config/
│   └── default.yaml            # Default configuration
├── db/
│   ├── migrations/             # Database migrations
│   │   └── 20240726225232_init_schema.sql
│   └── query/                  # SQL queries
│       ├── account.sql
│       ├── entry.sql
│       └── transfer.sql
├── pkg/
│   ├── api/                    # API handlers
│   ├── config/                 # Configuration logic
│   ├── db/sqlc/                # Generated SQL code
│   └── util/                   # Utility functions
├── transactionapi-chart/       # Helm chart
│   ├── Chart.yaml
│   ├── values.yaml
│   ├── README.md
│   └── templates/
│       ├── deployment.yaml
│       ├── service.yaml
│       ├── configmap.yaml
│       ├── secret.yaml
│       ├── ingress.yaml
│       ├── serviceaccount.yaml
│       ├── _helpers.tpl
│       └── NOTES.txt
└── main.go                     # Application entry point
```

## Quick Start

### Local Development

1. Start the application locally with Docker Compose:
   ```bash
   docker-compose -f docker-compose.yml up --build
   ```

2. The application will:
   - Wait for PostgreSQL to be ready
   - Run database migrations automatically
   - Start the API server on port 8080

3. Health Check:
   ```bash
   curl http://localhost:8080/health
   ```

### API Endpoints

- `GET /health` - Health check endpoint
- `POST /accounts` - Create a new account

### Container Building

Build the container image:
```bash
docker build -t transaction-api:latest .
```

### Running Without Docker Compose

If running the container standalone:
```bash
# First, ensure PostgreSQL is running
docker run -d --name postgres \
  -e POSTGRES_USER=test \
  -e POSTGRES_PASSWORD=test \
  -e POSTGRES_DB=bdb \
  -p 5432:5432 \
  postgres:12-alpine

# Run the application
docker run -p 8080:8080 \
  -e BANK_POSTGRES_HOST=host.docker.internal:5432 \
  -e BANK_POSTGRES_DATABASE=bdb \
  -e BANK_POSTGRES_USERNAME=test \
  -e BANK_POSTGRES_PASSWORD=test \
  -e BANK_POSTGRES_SSLMODE=disable \
  transaction-api:latest
```

## Kubernetes Deployment

### Prerequisites

1. Label your nodes for the API workload:
   ```bash
   kubectl label nodes node1 node2 node3 node4 node5 role=api
   ```

2. Ensure you have at least 5 nodes with the `role: api` label

### Deploy with Helm

1. Basic deployment:
   ```bash
   helm install transaction-api ./transactionapi-chart \
     --set secrets.postgresPassword=your-secure-password
   ```

2. Production deployment with custom values:
   ```bash
   helm install transaction-api ./transactionapi-chart \
     --set image.tag=v1.0.0 \
     --set secrets.postgresPassword=${POSTGRES_PASSWORD}
   ```

## CI/CD Pipeline

The GitHub Actions workflow (`ci-cd.yml`) provides:

1. **Testing**: Runs Go tests with PostgreSQL integration
2. **Building**: Creates multi-architecture Docker images (amd64, arm64)
3. **Publishing**: Pushes images to GitHub Container Registry (ghcr.io)

### Workflow Triggers

- Pull requests to main branch
- Pushes to main branch
- Version tags (v*)

### Image Tags

- `latest` - Latest main branch build
- `v1.0.0` - Semantic version tags
- `main` - Main branch builds
- `pr-123` - Pull request builds

## Configuration

### Environment Variables

All configuration can be overridden via environment variables with the `BANK_` prefix:

| Variable | Description | Default |
|----------|-------------|---------|
| `BANK_POSTGRES_HOST` | PostgreSQL host with port | `localhost:5432` |
| `BANK_POSTGRES_DATABASE` | Database name | `bdb` |
| `BANK_POSTGRES_USERNAME` | Database username | `test` |
| `BANK_POSTGRES_PASSWORD` | Database password | `test` |
| `BANK_POSTGRES_SSLMODE` | SSL mode | `disable` |
| `BANK_POSTGRES_AUTOMIGRATE` | Run migrations on startup | `true` |
| `BANK_APP_PORT` | API server port | `8080` |
| `BANK_APP_ENVIRONMENT` | Environment name | `dev` |
| `BANK_APP_HOST` | Host binding | `0.0.0.0` |

### Configuration File

Default configuration is loaded from `config/default.yaml`:

```yaml
app:
  environment: dev
  host: 0.0.0.0
  port: "8080"
postgres:
  host: localhost:5432
  database: bdb
  userName: test
  password: test
  sslMode: disable
  automigrate: true
```

## Architecture Features

### Docker Build

- Multi-stage builds for optimal size
- Non-root user execution
- Health check included
- PostgreSQL client for startup script
- Security hardening

### Kubernetes Deployment

1. **High Availability**: 5 replicas by default
2. **Node Affinity**: Runs only on `role: api` nodes
3. **Pod Anti-Affinity**: One pod per node
4. **Security Contexts**: Non-root, read-only root filesystem
5. **Resource Limits**: CPU and memory constraints
6. **Health Probes**: Liveness and readiness checks

### Database Migrations

- Uses Goose for migrations
- Automatically runs on startup if enabled
- Located in `db/migrations/`
- SQL migration files with timestamps

## Testing

Run unit tests locally:
```bash
go test -v -cover ./...
```

The CI pipeline runs tests automatically with a real PostgreSQL instance.

## Troubleshooting

### Common Issues

1. **Database Connection Failed**
   - Ensure PostgreSQL is running
   - Check environment variables
   - Verify network connectivity

2. **Migrations Not Found**
   - Check if `db/migrations` directory exists in container
   - Verify volume mounts if using custom setup

3. **Pod Scheduling Issues**
   - Ensure nodes are labeled with `role: api`
   - Check if you have enough nodes (5 required)

### Debugging Commands

```bash
# Check pod status
kubectl get pods -l app.kubernetes.io/name=transactionapi-chart

# View logs
kubectl logs -l app.kubernetes.io/name=transactionapi-chart --tail=100

# Check pod placement
kubectl get pods -o wide -l app.kubernetes.io/name=transactionapi-chart

# Verify node labels
kubectl get nodes -l role=api
```

## Security Notes

1. Always use strong passwords in production
2. Enable SSL for PostgreSQL connections in production
3. Use Kubernetes secrets or external secret management
4. The application runs as non-root user
5. Containers use read-only root filesystem where possible

