#!/bin/bash
# Despliega el servicio en el namespace de desarrollo

NAMESPACE="dev-${GIT_BRANCH//\//-}"
SERVICE=$1

# Crear namespace si no existe
kubectl create namespace $NAMESPACE --dry-run=client -o yaml | kubectl apply -f -

# Desplegar infraestructura compartida
helm upgrade --install infrastructure ./infrastructure \
  --namespace $NAMESPACE \
  --set postgresql.persistence.enabled=false \
  --set kafka.persistence.enabled=false

# Construir y desplegar el servicio específico
case $SERVICE in
  vote)
    docker build -t vote:dev-$GIT_COMMIT ./vote
    okteto build -t vote:dev-$GIT_COMMIT ./vote
    kubectl set image deployment/vote vote=vote:dev-$GIT_COMMIT -n $NAMESPACE
    ;;
  worker)
    docker build -t worker:dev-$GIT_COMMIT ./worker
    okteto build -t worker:dev-$GIT_COMMIT ./worker
    kubectl set image deployment/worker worker=worker:dev-$GIT_COMMIT -n $NAMESPACE
    ;;
  result)
    docker build -t result:dev-$GIT_COMMIT ./result
    okteto build -t result:dev-$GIT_COMMIT ./result
    kubectl set image deployment/result result=result:dev-$GIT_COMMIT -n $NAMESPACE
    ;;
esac

# Esperar a que esté listo
kubectl rollout status deployment/$SERVICE -n $NAMESPACE --timeout=120s