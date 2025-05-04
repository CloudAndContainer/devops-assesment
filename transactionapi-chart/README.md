# Transaction API Helm Chart

## Description

This Helm chart deploys the Transaction API application to a Kubernetes cluster.

## Prerequisites

- Kubernetes 1.21+
- Helm 3.0+
- PostgreSQL instance (external or deployed separately)
- Nodes labeled with `role: api` (minimum 5 nodes for default configuration)

## Configuration

### Required Values

The following values **must** be provided during installation:

```yaml
secrets:
  postgresPassword: "your-secure-password"
```

### Important Configuration Options

| Parameter | Description | Default |
|-----------|-------------|---------|
| `replicaCount` | Number of replicas | `5` |
| `image.repository` | Container image repository | `ghcr.io/your-org/transaction-api` |
| `image.tag` | Container image tag | `latest` |
| `nodeSelector.role` | Node selector for deployment | `api` |
| `config.postgres.host` | PostgreSQL host with port | `postgres.database.svc.cluster.local:5432` |
| `config.postgres.database` | PostgreSQL database name | `bdb` |
| `config.postgres.userName` | PostgreSQL username | `test` |
| `config.postgres.password` | PostgreSQL password (via secrets) | *Required* |
| `config.postgres.sslMode` | PostgreSQL SSL mode | `disable` |
| `config.postgres.automigrate` | Enable automatic migrations | `true` |
| `config.app.port` | Application port | `8080` |
| `config.app.environment` | Application environment | `prod` |
| `config.app.host` | Application host binding | `0.0.0.0` |

## Installation

### Basic Installation

```bash
helm install transaction-api ./transactionapi-chart \
  --set secrets.postgresPassword=YOUR_SECURE_PASSWORD
```

### Installation with Custom Values

Create a `values-override.yaml` file:

```yaml
secrets:
  postgresPassword: "your-secure-password"

config:
  postgres:
    host: "your-postgres-host:5432"
    userName: "custom-user"
    database: "custom-db"
    sslMode: "require"
  app:
    environment: "production"
```

Install with custom values:

```bash
helm install transaction-api ./transactionapi-chart \
  -f values-override.yaml
```

### Production Installation

For production deployments, consider using sealed secrets or external secret management:

```bash
helm install transaction-api ./transactionapi-chart \
  --set image.tag=v1.0.0 \
  --set ingress.enabled=true \
  --set ingress.hosts[0].host=api.yourdomain.com \
  --set ingress.hosts[0].paths[0].path=/ \
  --set ingress.hosts[0].paths[0].pathType=Prefix \
  --set ingress.tls[0].secretName=transaction-api-tls \
  --set ingress.tls[0].hosts[0]=api.yourdomain.com \
  --set secrets.postgresPassword=${POSTGRES_PASSWORD}
```

## Testing the Chart

To test the Helm chart template rendering:

```bash
helm template . --set secrets.postgresPassword=testpassword
```

## Upgrade

To upgrade the release:

```bash
helm upgrade transaction-api ./transactionapi-chart \
  -f values-override.yaml
```

## Uninstallation

To uninstall/delete the deployment:

```bash
helm uninstall transaction-api
```

## Architecture Details

This chart deploys the Transaction API with the following characteristics:

1. **High Availability**: Runs 5 replicas by default
2. **Node Affinity**: Pods are deployed only on nodes labeled with `role: api`
3. **Pod Anti-Affinity**: Ensures only one pod per node to maximize availability
4. **Health Checks**: Includes liveness and readiness probes
5. **Security**: Runs as non-root user with security contexts
6. **Configuration**: Uses ConfigMaps for non-sensitive data and Secrets for sensitive data
7. **Database Migrations**: Automatically runs Goose migrations on startup

## Prerequisites for Node Labeling

Before deploying this chart, ensure your nodes are properly labeled:

```bash
# Label nodes that should run the Transaction API
kubectl label nodes <node-name> role=api
```

To verify nodes are labeled:

```bash
kubectl get nodes -l role=api
```

Ensure you have at least 5 nodes labeled with `role: api` for the default configuration.

## Advanced Configuration

### Resource Management

Adjust resource requests and limits in `values.yaml`:

```yaml
resources:
  limits:
    cpu: 1000m
    memory: 1Gi
  requests:
    cpu: 500m
    memory: 512Mi
```

### Ingress Configuration

Enable ingress and configure TLS:

```yaml
ingress:
  enabled: true
  className: "nginx"
  annotations:
    kubernetes.io/ingress.class: nginx
    cert-manager.io/cluster-issuer: letsencrypt-prod
  hosts:
    - host: api.yourdomain.com
      paths:
        - path: /
          pathType: Prefix
  tls:
    - secretName: transaction-api-tls
      hosts:
        - api.yourdomain.com
```

### External PostgreSQL

To use an external PostgreSQL instance:

```yaml
config:
  postgres:
    host: "external-postgres.example.com:5432"
    database: "production_db"
    userName: "app_user"
    sslMode: "require"
    automigrate: true

secrets:
  postgresPassword: "${EXTERNAL_POSTGRES_PASSWORD}"
```

## Troubleshooting

### View Pod Status

```bash
kubectl get pods -l app.kubernetes.io/name=transactionapi-chart
```

### View Logs

```bash
kubectl logs -l app.kubernetes.io/name=transactionapi-chart --tail=100
```

### Check Pod Distribution

```bash
kubectl get pods -l app.kubernetes.io/name=transactionapi-chart -o wide
```

### Check Resource Usage

```bash
kubectl top pods -l app.kubernetes.io/name=transactionapi-chart
```

### Check Database Connection

```bash
kubectl exec -it <pod-name> -- wget -qO- http://localhost:8080/health
```

## Important Notes

1. The PostgreSQL password must be provided via the `secrets.postgresPassword` value
2. Nodes must be labeled with `role: api` for pod scheduling
3. The chart enforces pod anti-affinity to ensure high availability
4. Database migrations are enabled by default and run on startup using Goose
5. The application expects PostgreSQL host with port included (e.g., `postgres:5432`)
6. All environment variables use the `BANK_` prefix

## Environment Variables

The application uses the following environment variables (automatically configured by the chart):

| Variable | Description |
|----------|-------------|
| `BANK_POSTGRES_HOST` | PostgreSQL host with port |
| `BANK_POSTGRES_DATABASE` | Database name |
| `BANK_POSTGRES_USERNAME` | Database user |
| `BANK_POSTGRES_PASSWORD` | Database password |
| `BANK_POSTGRES_SSLMODE` | SSL mode |
| `BANK_POSTGRES_AUTOMIGRATE` | Enable migrations |
| `BANK_APP_PORT` | Application port |
| `BANK_APP_ENVIRONMENT` | Environment name |
| `BANK_APP_HOST` | Host binding |

