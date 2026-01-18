## ArgoCD Installation and Setup

Installation guide for ArgoCD using the official Helm chart and deployment to different environments.

### Prerequisites

- Kubernetes cluster (EKS 1.29+)
- Helm 3.x
- AWS Load Balancer Controller
- kubectl configured

### Installation

**Add ArgoCD Helm Repository**

```bash
helm repo add argo https://argoproj.github.io/argo-helm
helm repo update
```

**Install ArgoCD**

```bash
helm install argocd argo/argo-cd \
  --namespace argocd \
  --create-namespace \
  -f argocd/helm-values/values.yaml
```

**Get Admin Password**

```bash
kubectl -n argocd get secret argocd-initial-admin-secret -o jsonpath="{.data.password}" | base64 -d
```

**Access ArgoCD UI**

- URL: https://argocd.opsly.com
- Username: admin
- Password: (from above command)

### Deploy Applications to Different Environments

**Single Account Setup (All clusters in same AWS account)**

Deploy root application that manages all environments:

```bash
kubectl apply -f argocd/applications/root-application.yaml
```

This creates applications for:
- Dev environment (`ai-chatbot-dev`)
- Staging environment (`ai-chatbot-staging`)
- Production environment (`ai-chatbot-prod`)

**Multi-Account Setup (Clusters in different AWS accounts)**

1. Register clusters:

```bash
kubectl apply -f argocd/clusters/dev-cluster-secret.yaml
kubectl apply -f argocd/clusters/staging-cluster-secret.yaml
kubectl apply -f argocd/clusters/prod-cluster-secret.yaml
```

2. Deploy cluster-specific root applications:

```bash
kubectl apply -f argocd/applications/cluster-specific/root-application-dev-cluster.yaml
kubectl apply -f argocd/applications/cluster-specific/root-application-staging-cluster.yaml
kubectl apply -f argocd/applications/cluster-specific/root-application-prod-cluster.yaml
```

### Environment Configuration

**Dev Environment**
- Automated sync: Enabled
- Self-heal: Enabled
- Namespace: `chatbot-dev`
- Values file: `values_dev.yaml`

**Staging Environment**
- Automated sync: Enabled
- Self-heal: Enabled
- Namespace: `chatbot-staging`
- Values file: `values_staging.yaml`

**Production Environment**
- Automated sync: Disabled (manual sync required)
- Self-heal: Disabled
- Namespace: `chatbot-prod`
- Values file: `values_prod.yaml`

### Application Source

All applications read from:
- Repository: `https://github.com/kushal1313/opsly-devops`
- Branch: `main`
- Helm chart path: `helm-chart/ai-chatbot-helm`

### Upgrading ArgoCD

```bash
helm repo update
helm upgrade argocd argo/argo-cd \
  --namespace argocd \
  -f argocd/helm-values/values.yaml
```

### Uninstallation

```bash
helm uninstall argocd -n argocd
kubectl delete namespace argocd
```

### Troubleshooting

**Check ArgoCD Status**

```bash
kubectl get pods -n argocd
kubectl get applications -n argocd
```

**View Application Logs**

```bash
kubectl logs -n argocd -l app.kubernetes.io/name=argocd-server
kubectl logs -n argocd -l app.kubernetes.io/name=argocd-application-controller
```

**Sync Application Manually**

```bash
argocd app sync ai-chatbot-dev
argocd app sync ai-chatbot-staging
argocd app sync ai-chatbot-prod
```

**Check Application Status**

```bash
argocd app get ai-chatbot-dev
argocd app list
```

### Configuration

**High Availability**
- Controller: 3 replicas
- Server: 3 replicas with autoscaling
- Repo Server: 3 replicas

**Ingress**
- ALB Ingress Controller
- TLS termination at ALB
- Certificate ARN configured in `helm-values/values.yaml`

**RBAC**
- Configured in `helm-values/values.yaml` under `configs.rbac.policy.csv`
- Teams: org-admin, dev-team, staging-team, prod-team

**Notifications**
- Slack webhooks configured
- Email notifications for failed syncs
- Configure Slack token in ArgoCD secrets

### References

- [Official ArgoCD Helm Chart](https://github.com/argoproj/argo-helm/tree/main/charts/argo-cd)
- [ArgoCD Documentation](https://argo-cd.readthedocs.io/)
