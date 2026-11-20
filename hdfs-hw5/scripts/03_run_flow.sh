#!/usr/bin/env bash
set -euo pipefail
cd "$(dirname "$0")/.."
source ./env.sh

mkdir -p "$HW5_LOGS" reports

echo "Запуск потока Prefect"
export PREFECT_SERVER_ANALYTICS_ENABLED=false
"$PREFECT_VENV/bin/python" flows/hw5_flow.py 2>&1 | tee "${HW5_LOGS}/flow_run.log"
cp "${HW5_LOGS}/flow_run.log" reports/flow-run.txt
cp "${HW5_LOGS}/spark_submit.log" reports/run-spark.txt
