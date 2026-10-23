#!/usr/bin/env bash
set -euo pipefail
cd "$(dirname "$0")"

bash scripts/01_install.sh
bash scripts/02_start.sh
bash scripts/03_load_data.sh
bash scripts/04_check_clients.sh

echo "Развертывание Hive и проверки завершены"
