# Observability and Monitoring Strategy

## Overview

Observability strategy for the AI Chatbot Framework covering application metrics, logs, and infrastructure monitoring across all environments.

## Observability Stack

### Core Components

**Metrics Collection**
- Prometheus for metrics collection and storage
- Node Exporter for node-level metrics
- kube-state-metrics for Kubernetes object metrics
- Application metrics via Prometheus client libraries
- Prometheus Pushgateway for external/batch job metrics

**Visualization**
- Grafana for dashboards and visualization
- Grafana data sources: Prometheus, Loki, Alertmanager

**Logging**
- Grafana Loki for log aggregation and storage
- Promtail for log collection from Kubernetes pods
- Fluent Bit as alternative log shipper
- Application structured logging (JSON format)

**Alerting**
- Prometheus Alertmanager for metric-based alerts
- Alert routing to Slack, PagerDuty, Email
- ArgoCD notifications for deployment alerts

## Application Monitoring

### Backend Monitoring

**Key Metrics**
- Request rate (requests/second)
- Request latency (p50, p95, p99)
- Error rate (4xx, 5xx responses)
- Active connections
- Database query performance
- Cache hit/miss ratios
- ML model inference latency

**Health Checks**
- Liveness probe: `/health`
- Readiness probe: `/ready`
- Startup probe: `/startup`

### Frontend Monitoring

**Key Metrics**
- Page load time
- Time to First Byte (TTFB)
- First Contentful Paint (FCP)
- Largest Contentful Paint (LCP)
- Cumulative Layout Shift (CLS)
- JavaScript errors
- API call success/failure rates
- User session duration

## Infrastructure Monitoring

### EKS Cluster Monitoring

**Cluster Metrics**
- Node CPU utilization
- Node memory utilization
- Pod count per namespace
- Resource requests vs limits
- Network I/O
- Storage I/O

### Node Group Monitoring
- CPU usage trends
- Memory pressure
- Disk I/O
- Network throughput
- Pod scheduling success rate

## Cache Monitoring

### ElastiCache Valkey

**Metrics to Monitor**
- Cache hit rate
- Memory utilization
- Evictions
- Network throughput
- CPU utilization
- Connection count

**Alerts**
- Cache hit rate < 80%
- Memory utilization > 90%
- High eviction rate
- Connection errors

## Logging Strategy

### Log Levels

**Application Logs**
- ERROR: System errors, exceptions
- WARN: Warning conditions, degraded performance
- INFO: General information, request processing
- DEBUG: Detailed debugging information (dev only)

### Log Aggregation

**Promtail Configuration**
- Deployed as DaemonSet on each node
- Collects logs from `/var/log/pods` and `/var/log/containers`
- Parses structured JSON logs
- Adds Kubernetes labels (namespace, pod, container, node)
- Forwards logs to Loki

**Loki Log Streams**
- Labels: `namespace`, `app`, `pod`, `container`
- Retention: 30 days for INFO logs, 90 days for ERROR logs
- Log streams automatically created based on labels

**Log Labels Structure**
```
namespace=ai-chatbot
app=ai-chatbot-backend
container=backend
pod=ai-chatbot-backend-abc123
```

## Alerting Strategy

### Critical Alerts (P0)

**Application**
- Backend service down (0 healthy pods)
- Frontend service down (0 healthy pods)
- Error rate > 5% for 5 minutes
- P99 latency > 2 seconds for 10 minutes

**Infrastructure**
- Node CPU > 90% for 10 minutes
- Node memory > 95% for 5 minutes
- Pod eviction rate > 5 pods/minute
- Cluster autoscaler unable to scale

### Warning Alerts (P1)

**Application**
- Error rate > 2% for 15 minutes
- P95 latency > 1 second for 15 minutes
- Cache hit rate < 70% for 30 minutes
- Database connection pool > 80%

**Infrastructure**
- Node CPU > 80% for 30 minutes
- Node memory > 85% for 30 minutes
- HPA scaling frequently (> 5 times/hour)

### Informational Alerts (P2)

**Application**
- Deployment completed
- New version deployed
- Scheduled maintenance

**Infrastructure**
- Node group scaling events
- Certificate renewal
- Backup completion

## Implementation Steps

### Phase 1: Infrastructure Monitoring

**Step 1: Install Prometheus Stack with Loki**
```bash
helm repo add prometheus-community https://prometheus-community.github.io/helm-charts
helm repo add grafana https://grafana.github.io/helm-charts
helm repo update

helm install prometheus prometheus-community/kube-prometheus-stack \
  --namespace monitoring \
  --create-namespace \
  --set prometheus.prometheusSpec.retention=15d \
  --set alertmanager.alertmanagerSpec.retention=120h
```

**Step 2: Install Grafana Loki**
```bash
helm install loki grafana/loki-stack \
  --namespace monitoring \
  --set loki.persistence.enabled=true \
  --set loki.persistence.size=100Gi \
  --set promtail.enabled=true
```

**Step 3: Install Prometheus Pushgateway**
```bash
helm install pushgateway prometheus-community/prometheus-pushgateway \
  --namespace monitoring \
  --set service.type=ClusterIP
```

### Phase 3: Logging Setup

**Step 6: Configure Promtail (if not using Loki Stack)**
```bash
helm install promtail grafana/promtail \
  --namespace monitoring \
  --set config.clients[0].url=http://loki:3100/loki/api/v1/push
```

**Step 7: Configure Loki Retention**
- Set retention period in Loki configuration
- Configure retention policies per label (namespace, app)
- Set up log compaction for efficient storage

**Step 8: Configure Log Labels**
- Ensure application logs include required labels
- Configure Promtail to extract labels from log content
- Set up label-based log routing

### Phase 4: Dashboards

**Step 9: Access Grafana**
```bash
kubectl get secret --namespace monitoring prometheus-grafana -o jsonpath="{.data.admin-password}" | base64 --decode
kubectl port-forward --namespace monitoring svc/prometheus-grafana 3000:80
```

**Step 10: Configure Grafana Data Sources**
- Prometheus: `http://prometheus-server:80`
- Loki: `http://loki:3100`
- Alertmanager: `http://prometheus-alertmanager:9093`

**Step 11: Create Grafana Dashboards**

Application Dashboard:
- Request rate and latency (Prometheus)
- Error rates (Prometheus)
- Active sessions (Prometheus)
- Application logs (Loki)
- Database query performance (Prometheus)
- Cache metrics (Prometheus)

Infrastructure Dashboard:
- Node resource utilization (Prometheus)
- Pod resource usage (Prometheus)
- Network I/O (Prometheus)
- Storage metrics (Prometheus)
- Cluster logs (Loki)

Logs Dashboard:
- Log volume by namespace (Loki)
- Error log trends (Loki)
- Log search and filtering (Loki)
- Application log streams (Loki)

### Phase 5: Alerting

**Step 12: Configure Alertmanager**
- Set up notification receivers (Slack, PagerDuty, Email)
- Define alert routing rules based on severity
- Configure alert grouping and throttling
- Set up inhibition rules to prevent alert storms

**Step 13: Create Prometheus Alert Rules**
- Define alert rules in Prometheus
- Configure alert evaluation intervals
- Set up alert rule groups by service

**Step 14: Configure ArgoCD Notifications**
- Set up Slack/Email notifications for deployments
- Configure notification triggers for sync events
