#!/usr/bin/env bash
set -euo pipefail
cd "$(dirname "$0")/.."
source ./env.sh

DATES="2024-02-01 2024-02-02 2024-02-03 2024-02-04"

WORKDIR=$(mktemp -d)
trap 'rm -rf "$WORKDIR"' EXIT
CSV="${WORKDIR}/events.csv"

echo "event_id,user_id,event_type,product,price,quantity,dt" > "$CSV"
seed=7
for dt in $DATES; do
  awk -v seed="$seed" -v dt="$dt" 'BEGIN{
    srand(seed);
    split("view cart purchase refund", e, " ");
    split("Phone Laptop Tablet Headphones Watch", p, " ");
    for (i = 1; i <= 1000; i++)
      printf "%d,%d,%s,%s,%.2f,%d,%s\n", (seed-7)*1000+i, int(rand()*500)+1, e[int(rand()*4)+1], p[int(rand()*5)+1], rand()*2000+1, int(rand()*5)+1, dt
  }' >> "$CSV"
  seed=$((seed + 1))
done

echo "Загрузка данных в HDFS: ${HDFS_INPUT}"
hdfs dfs -mkdir -p "$HDFS_INPUT"
hdfs dfs -put -f "$CSV" "$HDFS_INPUT/"

hdfs dfs -ls "$HDFS_INPUT"
echo "Первые строки данных:"
hdfs dfs -cat "${HDFS_INPUT}/events.csv" | awk 'NR <= 5 {print}'

echo "Загрузка данных завершена"
