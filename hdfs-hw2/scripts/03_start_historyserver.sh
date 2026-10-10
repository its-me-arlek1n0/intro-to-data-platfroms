#!/usr/bin/env bash
set -euo pipefail
cd "$(dirname "$0")/.."
source env.sh

$SSH "$SSH_USER@$HISTORY_SERVER" '
  set -e
  source /etc/profile.d/hadoop.sh
  if ! mapred --daemon status historyserver 2>&1 | grep -q "historyserver is running as process"; then
    mapred --daemon start historyserver
  fi
'
curl --noproxy '*' -fsS --retry 15 --retry-connrefused --retry-delay 1 --max-time 5 \
  "http://$HISTORY_SERVER:19888/ws/v1/history/info" >/dev/null
echo "JobHistoryServer запущен"
