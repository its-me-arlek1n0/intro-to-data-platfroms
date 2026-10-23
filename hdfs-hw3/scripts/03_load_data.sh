#!/usr/bin/env bash
set -euo pipefail
cd "$(dirname "$0")/.."
source ./env.sh

PARTITIONS="2024-01-01 2024-01-02 2024-01-03"
HDFS_STAGE="/tmp/hw3_events"

WORKDIR=$(mktemp -d)
seed=1
for dt in $PARTITIONS; do
  awk -v seed="$seed" 'BEGIN{
    srand(seed);
    split("view cart purchase refund", e, " ");
    split("phone laptop tablet headphones watch", p, " ");
    for (i = 1; i <= 500; i++)
      printf "%d,%s,%s,%.2f\n", int(rand()*1000)+1, e[int(rand()*4)+1], p[int(rand()*5)+1], rand()*1000
  }' > "$WORKDIR/events_${dt}.csv"
  seed=$((seed + 1))
done

hdfs dfs -mkdir -p "$HDFS_STAGE"
for dt in $PARTITIONS; do
  hdfs dfs -mkdir -p "${HDFS_STAGE}/dt=${dt}"
  hdfs dfs -put -f "$WORKDIR/events_${dt}.csv" "${HDFS_STAGE}/dt=${dt}/"
done

beeline -u "jdbc:hive2://localhost:${HS2_PORT}" -f sql/create_table.sql

LOAD_SQL="$WORKDIR/load.sql"
: > "$LOAD_SQL"
for dt in $PARTITIONS; do
  echo "LOAD DATA INPATH '${HDFS_STAGE}/dt=${dt}/events_${dt}.csv' OVERWRITE INTO TABLE hw3.events PARTITION (dt='${dt}');" >> "$LOAD_SQL"
done
beeline -u "jdbc:hive2://localhost:${HS2_PORT}" -f "$LOAD_SQL"

beeline -u "jdbc:hive2://localhost:${HS2_PORT}" -e "SHOW PARTITIONS hw3.events;"
beeline -u "jdbc:hive2://localhost:${HS2_PORT}" -e "SELECT * FROM hw3.events WHERE dt='2024-01-01' LIMIT 10;"

rm -rf "$WORKDIR"
echo "Загрузка данных завершена"
