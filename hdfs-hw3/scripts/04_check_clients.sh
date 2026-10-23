#!/usr/bin/env bash
set -euo pipefail
cd "$(dirname "$0")/.."
source ./env.sh

mkdir -p "$HIVE_LOGS"

partitions=(2024-01-01 2024-01-02 2024-01-03)
pids=()

# Запуск трёх параллельных клиентов
for index in "${!partitions[@]}"; do
  client=$((index + 1))
  dt="${partitions[$index]}"

  beeline \
    --silent=true \
    --showHeader=false \
    --outputformat=tsv2 \
    -u "jdbc:hive2://localhost:${HS2_PORT}" \
    -e "SELECT * FROM hw3.events WHERE dt='${dt}' LIMIT 5;" \
    > "$HIVE_LOGS/client_${client}.log" 2>&1 &

  pids+=("$!")
done

# Проверка завершения запросов и полученных строк
rc=0
for index in "${!pids[@]}"; do
  client=$((index + 1))
  dt="${partitions[$index]}"
  log="$HIVE_LOGS/client_${client}.log"

  if wait "${pids[$index]}" &&
    awk -F '\t' -v dt="$dt" '
      NF == 5 && $1 ~ /^[0-9]+$/ && $5 == dt {rows++}
      END {exit (rows != 5)}
    ' "$log"; then
    echo "Проверка клиента $client: успешно, получено 5 строк"
  else
    echo "Проверка клиента $client: ошибка. Лог: $log"
    tail -n 10 "$log"
    rc=1
  fi
done

exit "$rc"
