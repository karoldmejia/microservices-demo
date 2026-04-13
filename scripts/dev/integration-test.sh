#!/bin/bash
set -e

NAMESPACE="${NAMESPACE:-infrastructure}"

echo "🧪 Ejecutando pruebas de integración en namespace: $NAMESPACE"

echo "Verificando pods..."
kubectl get pods -n $NAMESPACE

echo "Esperando a que Kafka esté listo..."
kubectl wait --for=condition=ready pod -l app.kubernetes.io/name=kafka -n $NAMESPACE --timeout=120s || true

echo "Configurando port-forwarding..."
kubectl port-forward -n $NAMESPACE svc/vote 8080:8080 &
VOTE_PF_PID=$!
kubectl port-forward -n $NAMESPACE svc/result 3000:80 &
RESULT_PF_PID=$!

sleep 5

echo "Enviando votos de prueba..."

for i in {1..10}; do
  curl -s -X POST http://localhost:8080/vote \
    -H "Content-Type: application/json" \
    -d '{"option":"taco"}' > /dev/null
  echo -n "."
done

for i in {1..5}; do
  curl -s -X POST http://localhost:8080/vote \
    -H "Content-Type: application/json" \
    -d '{"option":"burrito"}' > /dev/null
  echo -n "."
done
echo " Votos enviados"

echo "Esperando procesamiento (10 segundos)..."
sleep 10

echo "Obteniendo resultados..."
RESULT=$(curl -s http://localhost:3000/results)
echo "Resultados: $RESULT"

if echo "$RESULT" | grep -q '"tacos":10' && echo "$RESULT" | grep -q '"burritos":5'; then
  echo "Integration test passed"
  # Limpiar port-forwards
  kill $VOTE_PF_PID $RESULT_PF_PID 2>/dev/null || true
  exit 0
else
  echo "Integration test failed"
  echo "Esperado: tacos=10, burritos=5"
  echo "Obtenido: $RESULT"
  
  echo ""
  echo "Logs del worker:"
  kubectl logs -n $NAMESPACE deployment/worker --tail=20 2>/dev/null || echo "Worker logs no disponibles"
  
  kill $VOTE_PF_PID $RESULT_PF_PID 2>/dev/null || true
  exit 1
fi
EOF

chmod +x scripts/dev/integration-test.sh