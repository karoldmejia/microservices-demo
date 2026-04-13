#!/bin/bash
# Pruebas de integración del flujo completo

# Esperar a que Kafka esté listo
kubectl wait --for=condition=ready pod -l app=kafka -n $NAMESPACE --timeout=60s

# Enviar votos de prueba
for i in {1..10}; do
  curl -X POST http://vote.$NAMESPACE/vote \
    -H "Content-Type: application/json" \
    -d '{"option":"taco"}'
done

for i in {1..5}; do
  curl -X POST http://vote.$NAMESPACE/vote \
    -H "Content-Type: application/json" \
    -d '{"option":"burrito"}'
done

# Esperar procesamiento
sleep 5

# Verificar resultados
RESULT=$(curl -s http://result.$NAMESPACE/results)
if echo "$RESULT" | grep -q '"tacos":10' && echo "$RESULT" | grep -q '"burritos":5'; then
  echo "Integration test passed"
  exit 0
else
  echo "Integration test failed"
  exit 1
fi