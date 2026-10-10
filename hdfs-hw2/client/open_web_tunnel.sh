#!/usr/bin/env bash
set -euo pipefail
cd "$(dirname "$0")/.."
edge=${1:-111.88.130.12}
key=${2:-$HOME/.ssh/id_ed25519}
test -r "$key"

args=(-NT -i "$key" -o StrictHostKeyChecking=yes -o ExitOnForwardFailure=yes 
  -o ServerAliveInterval=30 -o ServerAliveCountMax=3)
while IFS=$'\t' read -r id service host backend port page; do
  [[ -z "$id" || "$id" == \#* ]] && continue
  args+=(-L "127.0.0.1:$port:127.0.0.1:$port")
  echo "$service ($host): http://127.0.0.1:$port$page"
done < config/web-interfaces.tsv
echo "оставте терминал открытым. Для остановки нажмите Ctrl и C."
exec ssh "${args[@]}" "team@$edge"
