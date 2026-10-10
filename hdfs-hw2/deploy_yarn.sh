#!/usr/bin/env bash
set -euo pipefail
cd "$(dirname "$0")"
source env.sh

hdfs dfsadmin -safemode get | grep -q 'Safe mode is OFF'
bash scripts/01_configure_yarn.sh
bash scripts/02_start_yarn.sh
bash scripts/03_start_historyserver.sh
bash scripts/04_publish_web.sh
bash scripts/05_check_yarn.sh
