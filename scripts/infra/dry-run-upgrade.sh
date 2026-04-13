#!/bin/bash
set -e

NAMESPACE="infrastructure"
CHART_PATH="./infrastructure"

echo "🔍 Rendering Helm templates..."

helm template infrastructure $CHART_PATH \
  --namespace $NAMESPACE \
  --set postgresql.persistence.size=10Gi \
  --set kafka.persistence.size=10Gi > rendered.yaml

echo "Helm template OK"

echo "Validating with kube-score..."
kube-score score rendered.yaml || true

echo "Validating with kubectl (client-side)..."
kubectl apply --dry-run=client -f rendered.yaml

echo "Dry-run validation OK"