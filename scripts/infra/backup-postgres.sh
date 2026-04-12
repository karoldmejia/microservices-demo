#!/bin/bash
# Backup de PostgreSQL (para operaciones)

BACKUP_FILE="postgres-backup-$(date +%Y%m%d-%H%M%S).sql"

# Obtener pod de PostgreSQL
POD=$(kubectl get pods -n infrastructure -l app=postgresql -o jsonpath='{.items[0].metadata.name}')

# Ejecutar backup
kubectl exec -n infrastructure $POD -- \
  pg_dump -U okteto votes > /tmp/$BACKUP_FILE

# Subir a S3 (o similar)
aws s3 cp /tmp/$BACKUP_FILE s3://votes-backups/

echo "Backup completed: $BACKUP_FILE"