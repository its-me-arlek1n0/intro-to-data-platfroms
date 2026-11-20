#!/usr/bin/env bash
set -euo pipefail
cd "$(dirname "$0")/.."
source ./env.sh

echo "Удаление таблицы ${DB_NAME}.${TABLE_NAME}..."
"$HIVE_HOME/bin/beeline" -u "jdbc:hive2://localhost:${HS2_PORT}" \
  -e "DROP TABLE IF EXISTS ${DB_NAME}.${TABLE_NAME};"

echo "Удаление входных данных ${HDFS_INPUT}..."
hdfs dfs -rm -r -f "$HDFS_INPUT" || true

echo "Очистка завершена"
