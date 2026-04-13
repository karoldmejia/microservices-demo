#!/bin/bash
set -e

NAMESPACE="${NAMESPACE:-infrastructure}"

echo "Ejecutando pruebas de integración en namespace: $NAMESPACE"

# Verificar pods
echo "Verificando pods..."
kubectl get pods -n $NAMESPACE

# Configurar port-forwarding
echo "Configurando port-forwarding..."
kubectl port-forward -n $NAMESPACE svc/vote 8080:8080 &
VOTE_PF_PID=$!
kubectl port-forward -n $NAMESPACE svc/result 3000:80 &
RESULT_PF_PID=$!

sleep 5

# Probar primero qué endpoint funciona
echo "Probando endpoints de Result App..."
curl -s http://localhost:3000/ && echo " - Endpoint / funciona" || echo " - Endpoint / no funciona"
curl -s http://localhost:3000/results && echo " - Endpoint /results funciona" || echo " - Endpoint /results no funciona"
curl -s http://localhost:3000/result && echo " - Endpoint /result funciona" || echo " - Endpoint /result no funciona"
curl -s http://localhost:3000/api/results && echo " - Endpoint /api/results funciona" || echo " - Endpoint /api/results no funciona"

echo ""
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

# Esperar procesamiento
echo "⏳ Esperando procesamiento (10 segundos)..."
sleep 10

# Intentar diferentes endpoints para obtener resultados
echo "Obteniendo resultados..."

# Probar /results primero
RESULT=$(curl -s http://localhost:3000/results 2>/dev/null)
if [ -z "$RESULT" ] || echo "$RESULT" | grep -q "Cannot GET"; then
  # Si falla, probar raíz
  RESULT=$(curl -s http://localhost:3000/ 2>/dev/null)
fi

echo "Resultados obtenidos: $RESULT"

# Verificar resultados (ajustar según el formato real)
if echo "$RESULT" | grep -q "taco" || echo "$RESULT" | grep -q "burrito"; then
  echo "Integration test passed - Resultados recibidos"
  kill $VOTE_PF_PID $RESULT_PF_PID 2>/dev/null || true
  exit 0
else
  echo "Integration test failed - No se recibieron resultados"
  echo ""
  echo "Logs del worker:"
  kubectl logs -n $NAMESPACE deployment/worker --tail=20
  echo ""
  echo "Logs de result app:"
  kubectl logs -n $NAMESPACE deployment/result --tail=20
  
  kill $VOTE_PF_PID $RESULT_PF_PID 2>/dev/null || true
  exit 1
fi
EOF

chmod +x scripts/dev/integration-test.sh