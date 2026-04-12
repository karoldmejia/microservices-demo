#!/bin/bash
# Valida el chart de Helm

CHART_PATH="./infrastructure"

# Lint
helm lint $CHART_PATH

# Template rendering
helm template test $CHART_PATH \
  --set postgresql.persistence.enabled=false \
  --set kafka.persistence.enabled=false \
  > /tmp/rendered.yaml

# kube-score validation
kube-score score /tmp/rendered.yaml \
  --ignore-test pod-networkpolicy \
  --output-format ci

# checkov security scan
checkov -f /tmp/rendered.yaml

echo "Chart validation passed"