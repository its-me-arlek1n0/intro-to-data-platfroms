#!/usr/bin/env bash
set -euo pipefail
cd "$(dirname "$0")/.."
source env.sh

REPORT=$($SSH "${SSH_USER}@${NAMENODE}" 'source /etc/profile.d/hadoop.sh && hdfs dfsadmin -report 2>&1') || {
  echo "$REPORT"
  echo "NameNode не отвечает. Кластер запущен? (scripts/04_start_cluster.sh)"
  exit 1
}
echo "$REPORT" | grep -E "Live datanodes|Dead datanodes|Hostname" || true

LIVE=$(echo "$REPORT" | grep -oP 'Live datanodes \(\K[0-9]+' || echo 0)
if [ "$LIVE" -ne 3 ]; then
  echo "ОШИБКА: живых DataNode = $LIVE, а надо 3"
  exit 1
fi

for node in $ALL_NODES; do
  $SSH "${SSH_USER}@${node}" 'pgrep -af "org.apache.hadoop.hdfs.server" | grep -v "pgrep -af" | sed -E "s/^([0-9]+).*server\.[a-z]+\.([A-Za-z]+).*/\2 (pid \1)/" | grep -E "NameNode|DataNode" || echo "ничего не запущено"' | sed "s/^/${node}: /"
done

FAIL=0
for node in $ALL_NODES; do
  ERRORS=$($SSH "${SSH_USER}@${node}" 'grep -hE "FATAL|\bERROR\b" /opt/hadoop/logs/*.log 2>/dev/null | grep -vE "SIGTERM" | head -5' || true)
  if [ -n "$ERRORS" ]; then
    echo "$ERRORS" | sed "s/^/${node}: /"
    FAIL=1
  fi
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
fi
