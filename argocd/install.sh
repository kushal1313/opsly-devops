#!/bin/bash

set -e

echo "Installing ArgoCD using official Helm chart..."

helm repo add argo https://argoproj.github.io/argo-helm
helm repo update

echo "Installing ArgoCD..."
helm install argocd argo/argo-cd \
  --namespace argocd \
  --create-namespace \
  -f argocd/helm-values/values.yaml

echo "Waiting for ArgoCD to be ready..."
kubectl wait --for=condition=available --timeout=300s deployment/argocd-server -n argocd || true
kubectl wait --for=condition=available --timeout=300s deployment/argocd-application-controller -n argocd || true

echo "Getting ArgoCD admin password..."
ARGOCD_PASSWORD=$(kubectl -n argocd get secret argocd-initial-admin-secret -o jsonpath="{.data.password}" 2>/dev/null | base64 -d || echo "Password not available yet")

echo ""
echo "=========================================="
echo "ArgoCD Installation Complete!"
echo "=========================================="
echo "Admin Password: $ARGOCD_PASSWORD"
echo "UI URL: https://argocd.opsly.com"
echo ""
echo "To deploy applications:"
echo "  Single account: kubectl apply -f argocd/applications/root-application.yaml"
echo "  Multi-account: kubectl apply -f argocd/applications/cluster-specific/"
echo "=========================================="

