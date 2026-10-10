#!/usr/bin/env bash
set -euo pipefail
cd "$(dirname "$0")/.."
source env.sh

if [ "${1:-}" != --confirm ]; then
  echo "Остановка YARN требует согласования. После него запустите скрипт с --confirm."
  exit 1
fi
apps=$(yarn application -list -appStates SUBMITTED,ACCEPTED,RUNNING)
echo "$apps"
if ! echo "$apps" | grep -q 'Total number of applications.*:0$'; then
  echo "Есть незавершённые приложения или не удалось проверить их число. Остановка отменена."
  exit 1
fi

$SSH "$SSH_USER@$HISTORY_SERVER" 'source /etc/profile.d/hadoop.sh && mapred --daemon stop historyserver'
for node in $NODE_MANAGERS; do
  $SSH "$SSH_USER@$node" 'source /etc/profile.d/hadoop.sh && yarn --daemon stop nodemanager'
done
$SSH "$SSH_USER@$RESOURCE_MANAGER" 'source /etc/profile.d/hadoop.sh && yarn --daemon stop resourcemanager'
echo "YARN и JobHistoryServer остановлены. HDFS продолжает работать."
