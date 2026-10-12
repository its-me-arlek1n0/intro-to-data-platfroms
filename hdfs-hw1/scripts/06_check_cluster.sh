#!/usr/bin/env bash
set -euo pipefail
cd "$(dirname "$0")/.."
source env.sh

REPORT=$($SSH "${SSH_USER}@${NAMENODE}" 'source /etc/profile.d/hadoop.sh && hdfs dfsadmin -report -live 2>&1') || {
  echo "$REPORT"
  echo "NameNode не отвечает. Кластер запущен? (scripts/04_start_cluster.sh)"
  exit 1
}
LIVE=$(echo "$REPORT" | grep -c '^Decommission Status : Normal$' || true)
echo "Действующих DataNode: $LIVE"
if [ "$LIVE" -ne 3 ]; then
  echo "ОШИБКА: действующих DataNode = $LIVE, а надо 3"
  exit 1
fi

for node in $DATANODES; do
  echo "$REPORT" | awk -v host="$node" '
    /^Hostname:/ {expected = ($2 == host)}
    /^Decommission Status/ && expected && $NF == "Normal" {found = 1}
    END {exit !found}
  '
  echo "DataNode ($node): доступен"
done

for node in $ALL_NODES; do
  if [ "$node" != "$NAMENODE" ] && [ "$node" != "$SECONDARY_NN" ] && [[ " $DATANODES " != *" $node "* ]]; then
    echo "$node: управляющий узел, HDFS-демоны не требуются"
    continue
  fi
  $SSH "${SSH_USER}@${node}" 'pgrep -af "org.apache.hadoop.hdfs.server" | grep -v "pgrep -af" | sed -E "s/^([0-9]+).*server\.[a-z]+\.([A-Za-z]+).*/\2 (pid \1)/" | grep -E "NameNode|DataNode" || echo "ничего не запущено"' | sed "s/^/${node}: /"
done

FAIL=0
for daemon in namenode secondarynamenode datanode; do
  case "$daemon" in
    namenode) nodes="$NAMENODE" ;;
    secondarynamenode) nodes="$SECONDARY_NN" ;;
    datanode) nodes="$DATANODES" ;;
  esac
  for node in $nodes; do
    log="/opt/hadoop/logs/hadoop-${SSH_USER}-${daemon}-${node}.log"
    if ! ERRORS=$($SSH "${SSH_USER}@${node}" "awk '
      /STARTUP_MSG: Starting/ {errors = \"\"}
      / (ERROR|FATAL) / && !/SIGTERM/ {errors = errors \$0 ORS}
      END {printf \"%s\", errors}
    ' '$log'"); then
      echo "$node: не удалось прочитать $log"
      FAIL=1
    elif [ -n "$ERRORS" ]; then
      echo "$ERRORS" | sed "s/^/${node} (${daemon}): /"
      FAIL=1
    fi
  done
done

$SSH "${SSH_USER}@${NAMENODE}" '
  source /etc/profile.d/hadoop.sh
  echo "hello hdfs" > /tmp/smoke.txt
  hdfs dfs -mkdir -p /tmp
  hdfs dfs -put -f /tmp/smoke.txt /tmp/smoke.txt
  hdfs dfs -cat /tmp/smoke.txt
'

if [ "$FAIL" -eq 0 ]; then
  echo "все ок"
else
  echo "в логах есть ошибки"
  exit 1
fi
