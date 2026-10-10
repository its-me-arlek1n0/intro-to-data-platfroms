#!/usr/bin/env bash
set -euo pipefail
cd "$(dirname "$0")/.."
source env.sh

$SSH "$SSH_USER@$RESOURCE_MANAGER" '
  set -e
  source /etc/profile.d/hadoop.sh
  if ! yarn --daemon status resourcemanager 2>&1 | grep -q "resourcemanager is running as process"; then
    yarn --daemon start resourcemanager
  fi
'
curl --noproxy '*' -fsS --retry 15 --retry-connrefused --retry-delay 1 --max-time 5 \
  "http://$RESOURCE_MANAGER:8088/ws/v1/cluster/info" >/dev/null

for node in $NODE_MANAGERS; do
  $SSH "$SSH_USER@$node" '
    set -e
    source /etc/profile.d/hadoop.sh
    if ! yarn --daemon status nodemanager 2>&1 | grep -q "nodemanager is running as process"; then
      yarn --daemon start nodemanager
    fi
  '
  curl --noproxy '*' -fsS --retry 15 --retry-connrefused --retry-delay 1 --max-time 5 \
    "http://$node:8042/ws/v1/node/info" >/dev/null
done
echo "ResourceManager и NodeManager запущены"
