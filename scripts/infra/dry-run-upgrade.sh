#!/bin/bash
set -e

CHART_PATH="./infrastructure"


if [ ! -d "$CHART_PATH" ]; then
  echo "Error: Chart directory not found: $CHART_PATH"
  exit 1
fi

helm lint $CHART_PATH

helm template infrastructure $CHART_PATH \
  --namespace infrastructure \
  --set postgresql.persistence.enabled=false \
  --set kafka.persistence.enabled=false \
  > /tmp/dev-rendered.yaml

helm template infrastructure $CHART_PATH \
  --namespace infrastructure \
  --set postgresql.persistence.enabled=true \
  --set postgresql.persistence.size=10Gi \
  --set kafka.persistence.enabled=true \
  --set kafka.persistence.size=10Gi \
  > /tmp/prod-rendered.yaml

echo "Templates renderizados correctamente"


echo ""
echo "Estadísticas del chart:"
echo "  - Archivos generados: $(cat /tmp/prod-rendered.yaml | grep -c "apiVersion:") recursos Kubernetes"
echo "  - Tamaño del template: $(wc -l < /tmp/prod-rendered.yaml) líneas"

echo ""
echo "Dry-run completado exitosamente"
EOF

chmod +x scripts/infra/dry-run-upgrade.sh