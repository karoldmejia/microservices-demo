#!/bin/bash
# Simula el upgrade en el clúster real

NAMESPACE="infrastructure"
CHART_PATH="./infrastructure"

# Instalar helm-diff si no está
helm plugin install https://github.com/databus23/helm-diff || true

# Mostrar diferencias
helm diff upgrade infrastructure $CHART_PATH \
  --namespace $NAMESPACE \
  --set postgresql.persistence.size=10Gi \
  --set kafka.persistence.size=10Gi

# Dry-run real
helm upgrade --install infrastructure $CHART_PATH \
  --namespace $NAMESPACE \
  --set postgresql.persistence.size=10Gi \
  --set kafka.persistence.size=10Gi \
  --dry-run --debug