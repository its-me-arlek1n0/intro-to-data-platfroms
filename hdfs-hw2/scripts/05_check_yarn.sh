#!/usr/bin/env bash
set -euo pipefail
cd "$(dirname "$0")/.."
source env.sh

# NodeManager должны зарегистрироваться в ResourceManager.
for attempt in {1..15}; do
  nodes=$(yarn node -list -all)
  running=$(echo "$nodes" | awk '$2 == "RUNNING" {n++} END {print n+0}')
  total=$(echo "$nodes" | awk '$1 ~ /^Total/ {sub(".*:", "", $NF); print $NF}')
  if [ "$running" -eq 3 ] && [ "$total" = 3 ]; then break; fi
  sleep 2
done
echo "$nodes"
test "$running" -eq 3
test "$total" = 3
for node in $NODE_MANAGERS; do
  echo "$nodes" | awk -v host="$node" '$2 == "RUNNING" && index($1, host ":") == 1 {found=1} END {exit !found}'
done

# HDFS из дз1 должна продолжать работать
report=$(hdfs dfsadmin -report)
echo "$report" | grep -E 'Live datanodes|Dead datanodes|Hostname'
echo "$report" | grep -q 'Live datanodes (3)'
if echo "$report" | grep -Eq '^Dead datanodes \([1-9]'; then
  echo "Есть недоступные DataNode"
  exit 1
fi
hdfs fsck / | grep 'Status: HEALTHY'

systemctl --user is-active hdfs-hw2-web.service
test "$(loginctl show-user "$USER" -p Linger --value)" = yes
while IFS=$'\t' read -r id service host backend port page; do
  [[ -z "$id" || "$id" == \#* ]] && continue
  curl --noproxy '*' -fsSL --retry 10 --retry-connrefused --retry-delay 1 --max-time 10 \
    "http://127.0.0.1:$port$page" >/dev/null
  echo "$service ($host): http://127.0.0.1:$port$page — доступен"
done < config/web-interfaces.tsv
echo "Все проверки пройдены"
