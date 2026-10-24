#!/usr/bin/env bash
set -euo pipefail
cd "$(dirname "$0")/.."
source ./env.sh

mkdir -p "$HW4_LOGS" reports

echo "Запуск Spark-приложения под управлением YARN"
spark-submit \
  --master yarn \
  --deploy-mode client \
  app/spark_job.py 2>&1 | tee "${HW4_LOGS}/spark_submit.log"

APP_ID=$(awk '/^YARN application ID: / {id=$4} END {print id}' "$HW4_LOGS/spark_submit.log")
if [[ ! "$APP_ID" =~ ^application_[0-9]+_[0-9]+$ ]]; then
  echo "Не удалось определить ID текущего приложения YARN"
  exit 1
fi

echo "Идентификатор приложения в YARN: ${APP_ID}"
for i in $(seq 1 15); do
  yarn application -status "$APP_ID" > reports/yarn-status.txt
  state=$(awk '/^[[:space:]]*State[[:space:]]*:/ {print $NF}' reports/yarn-status.txt)
  final_state=$(awk '/^[[:space:]]*Final-State[[:space:]]*:/ {print $NF}' reports/yarn-status.txt)

  if [ "$state" = "FINISHED" ] && [ "$final_state" = "SUCCEEDED" ]; then
    echo "Состояние приложения: $state / $final_state"
    echo "Выполнение Spark-приложения завершено"
    exit 0
  fi
  if [ "$state" = "FAILED" ] || [ "$state" = "KILLED" ] || [ "$state" = "FINISHED" ]; then
    cat reports/yarn-status.txt
    echo "Приложение завершилось без успешного результата"
    exit 1
  fi
  sleep 2
done

echo "Не удалось дождаться итогового состояния приложения"
exit 1
