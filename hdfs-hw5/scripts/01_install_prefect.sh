#!/usr/bin/env bash
set -euo pipefail
cd "$(dirname "$0")/.."
source ./env.sh

if [ ! -d "$PREFECT_VENV" ]; then
  echo "Создание виртуального окружения ${PREFECT_VENV}..."
  python3 -m venv "$PREFECT_VENV"
fi

echo "Установка Prefect..."
"$PREFECT_VENV/bin/pip" install --quiet --upgrade pip
"$PREFECT_VENV/bin/pip" install --quiet "prefect>=3,<4"

"$PREFECT_VENV/bin/prefect" version
echo "Установка Prefect завершена"
