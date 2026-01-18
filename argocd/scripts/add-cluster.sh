#!/bin/bash

set -e

CLUSTER_NAME=$1
CLUSTER_ENDPOINT=$2
CLUSTER_ACCOUNT_ID=$3
ROLE_ARN=$4

if [ -z "$CLUSTER_NAME" ] || [ -z "$CLUSTER_ENDPOINT" ] || [ -z "$CLUSTER_ACCOUNT_ID" ] || [ -z "$ROLE_ARN" ]; then
  echo "Usage: $0 <cluster-name> <cluster-endpoint> <account-id> <role-arn>"
  echo "Example: $0 dev-cluster https://dev-cluster.eks.us-east-1.amazonaws.com 111111111111 arn:aws:iam::111111111111:role/argocd-dev-cluster-role"
  exit 1
fi

echo "Adding cluster $CLUSTER_NAME to ArgoCD..."

kubectl create secret generic $CLUSTER_NAME \
  --from-literal=name=$CLUSTER_NAME \
  --from-literal=server=$CLUSTER_ENDPOINT \
  --from-literal=config="{\"bearerToken\":\"\",\"tlsClientConfig\":{\"insecure\":false,\"caData\":\"\"},\"awsAuthConfig\":{\"clusterName\":\"$CLUSTER_NAME\",\"roleARN\":\"$ROLE_ARN\"}}" \
  --dry-run=client -o yaml | \
  kubectl label --local -f - argocd.argoproj.io/secret-type=cluster -o yaml | \
  kubectl apply -f -

echo "Cluster $CLUSTER_NAME added successfully!"
echo "Verify in ArgoCD UI: Settings > Clusters"

