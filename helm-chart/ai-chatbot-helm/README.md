## AI Chatbot Framework Helm Chart

Parent Helm chart for deploying the AI Chatbot Framework application on EKS.

### Chart Structure

```
ai-chatbot-helm/
├── Chart.yaml
├── values.yaml
├── values_dev.yaml
├── values_staging.yaml
├── values_prod.yaml
├── templates/
│   ├── _helpers.tpl
│   ├── configmap.yaml
│   ├── secrets.yaml
│   ├── ingress.yaml
│   └── NOTES.txt
└── charts/
    ├── backend/
    └── frontend/
```

### Components

**Parent Chart**
- ConfigMap for shared configuration
- Secrets for MongoDB Atlas and ElastiCache Valkey connection strings
- Ingress for routing traffic

**Backend Subchart**
- FastAPI backend deployment
- Service, ServiceAccount, HPA
- Health checks configured
- ML workload node selectors and tolerations

**Frontend Subchart**
- Next.js frontend deployment
- Service, ServiceAccount, optional HPA
- Health checks configured

### Prerequisites

1. Kubernetes cluster (EKS 1.29+)
2. Helm 3.x
3. AWS Load Balancer Controller
4. MongoDB Atlas cluster
5. ElastiCache Valkey cluster

### Installation

Update dependencies:

```bash
cd helm-chart/ai-chatbot-helm
helm dependency update
```

Install for development:

```bash
helm install ai-chatbot . -f values_dev.yaml -n chatbot-dev --create-namespace
```

Install for staging:

```bash
helm install ai-chatbot . -f values_staging.yaml -n chatbot-staging --create-namespace
```

Install for production:

```bash
helm install ai-chatbot . -f values_prod.yaml -n chatbot-prod --create-namespace
```

### Configuration

**Environment-specific values files apply to subcharts**

Values under `backend:` are passed to the backend subchart, values under `frontend:` are passed to the frontend subchart.

**Key Configuration Values**

- `global.env`: Environment name
- `backend.replicaCount`: Backend replica count
- `backend.image.repository`: Backend ECR repository
- `backend.image.tag`: Backend image tag
- `backend.resources`: Resource requests/limits for ML workloads
- `backend.autoscaling`: HPA configuration
- `backend.serviceAccount.annotations`: IRSA IAM role ARN
- `frontend.replicaCount`: Frontend replica count
- `frontend.image.repository`: Frontend ECR repository
- `frontend.image.tag`: Frontend image tag
- `externalServices.mongodb.uri`: MongoDB Atlas connection string
- `externalServices.redis.endpoint`: ElastiCache Valkey endpoint (e.g., `cluster-name.abc123.cache.amazonaws.com`)
- `externalServices.redis.port`: ElastiCache Valkey port (default: 6379)
- `externalServices.redis.tls`: Enable TLS for ElastiCache Valkey (default: true)
- `ingress.host`: Ingress hostname
- `ingress.certificateArn`: AWS ACM certificate ARN

### IRSA Configuration

Configure IAM role ARNs in environment-specific values files:

```yaml
backend:
  serviceAccount:
    annotations:
      eks.amazonaws.com/role-arn: arn:aws:iam::333333333333:role/ROLE_NAME
```

The IAM role must have a trust relationship with your EKS cluster's OIDC provider.

### ElastiCache Valkey Configuration

ElastiCache Valkey endpoints use a different format than standard Redis. Configure the endpoint, port, and TLS settings:

```yaml
externalServices:
  redis:
    endpoint: "cluster-name.abc123.cache.amazonaws.com"
    port: 6379
    tls: true
```

The chart automatically constructs the Redis connection URL (`rediss://` for TLS, `redis://` for non-TLS) and stores it in the `REDIS_URL` secret.

For IAM authentication with ElastiCache Valkey, ensure your ServiceAccount IAM role has `elasticache:Connect` permission.

### Upgrading

```bash
helm upgrade ai-chatbot . -f values_prod.yaml -n chatbot-prod
```

### Uninstallation

```bash
helm uninstall ai-chatbot -n chatbot-prod
```
