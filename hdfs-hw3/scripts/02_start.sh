#!/usr/bin/env bash
set -euo pipefail
cd "$(dirname "$0")/.."
source ./env.sh

mkdir -p "$HIVE_LOGS"

if ! pgrep -f "proc_metastore" >/dev/null; then
  echo "Запуск метастора"
  nohup hive --service metastore > "$HIVE_LOGS/metastore.log" 2>&1 &
fi

for i in $(seq 1 30); do
  if (exec 3<>"/dev/tcp/127.0.0.1/${METASTORE_PORT}") 2>/dev/null; then
    exec 3>&- 3<&-
    echo "Метастор запущен на порту ${METASTORE_PORT}"
    break
  fi
  sleep 2
  if [ "$i" -eq 30 ]; then
    echo "Ошибка запуска метастора. Лог: $HIVE_LOGS/metastore.log"
    exit 1
  fi
done

if ! pgrep -f "proc_hiveserver2" >/dev/null; then
  echo "Запуск HiveServer2"
  nohup hive --service hiveserver2 > "$HIVE_LOGS/hiveserver2.log" 2>&1 &
fi

for i in $(seq 1 40); do
  if beeline -u "jdbc:hive2://localhost:${HS2_PORT}" -e "show databases;" 2>/dev/null | grep -q "default"; then
    echo "HiveServer2 запущен на порту ${HS2_PORT}"
    exit 0
  fi
  sleep 5
  if [ "$i" -eq 40 ]; then
    echo "Ошибка запуска HiveServer2. Лог: $HIVE_LOGS/hiveserver2.log"
    exit 1
  fi
done
