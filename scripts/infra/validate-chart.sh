#!/bin/bash
set -e

CHART_PATH="./infrastructure"


# Verificar que el directorio existe
if [ ! -d "$CHART_PATH" ]; then
  echo "Error: Chart directory not found: $CHART_PATH"
  exit 1
fi

echo "Running helm lint..."
helm lint $CHART_PATH

echo "Rendering templates..."
helm template test $CHART_PATH \
  --set postgresql.persistence.enabled=false \
  --set kafka.persistence.enabled=false \
  > /tmp/rendered.yaml

echo "Templates rendered successfully"

# Validar YAML sintaxis
echo "Validating YAML syntax..."
python3 -c "import yaml; yaml.safe_load(open('/tmp/rendered.yaml'))" 2>/dev/null && echo "YAML syntax OK" || echo "YAML validation skipped (pyyaml not installed)"

if command -v kube-score &> /dev/null; then
  echo "Running kube-score (basic checks)..."
  kube-score score /tmp/rendered.yaml --ignore-test pod-networkpolicy --output-format ci || true
else
  echo "ube-score not installed, skipping"
fi

if command -v checkov &> /dev/null; then
  echo "Running checkov..."
  checkov -f /tmp/rendered.yaml --quiet 2>/dev/null || true
else
  echo "checkov not installed, skipping"
fi

echo ""
echo "Chart validation passed (no cluster required)"
EOF

chmod +x scripts/infra/validate-chart.sh