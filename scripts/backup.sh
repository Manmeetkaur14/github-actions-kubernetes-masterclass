#!/bin/bash
set -e

BACKUP_DATE=$(date +%Y%m%d_%H%M%S)
BACKUP_DIR="./backups/${BACKUP_DATE}"
NAMESPACE="skillpulse"
S3_BUCKET="s3://skillpulse-backups-486036174293"

echo "Starting backup..."
mkdir -p "${BACKUP_DIR}"

kubectl get all -n ${NAMESPACE} -o yaml > "${BACKUP_DIR}/resources.yaml"
kubectl get cm,secrets -n ${NAMESPACE} -o yaml > "${BACKUP_DIR}/config_secrets.yaml"

DB_POD=$(kubectl get pods -n ${NAMESPACE} -l app=mysql -o jsonpath="{.items[0].metadata.name}")

kubectl exec -n ${NAMESPACE} "${DB_POD}" -- sh -c 'mysqldump -u root -prootpassword123 --all-databases' > "${BACKUP_DIR}/db_dump.sql"

tar -czf "${BACKUP_DIR}.tar.gz" -C "./backups" "${BACKUP_DATE}"

echo "Backup completed locally."
