#!/usr/bin/env bash
set -euo pipefail
cd "$(dirname "$0")/.."
source ./env.sh

WORKDIR=$(mktemp -d)
trap 'rm -rf "$WORKDIR"' EXIT
CSV="${WORKDIR}/events.csv"

python3 - "$CSV" <<'PY'
import csv
import random
import sys

random.seed(42)

event_types = ["view", "cart", "purchase", "refund"]
products = ["Phone", "Laptop", "Tablet", "Headphones", "Watch"]
dates = ["2024-02-01", "2024-02-02", "2024-02-03", "2024-02-04"]

with open(sys.argv[1], "w", newline="") as f:
    writer = csv.writer(f)
    writer.writerow(["event_id", "user_id", "event_type", "product", "price", "quantity", "dt"])
    event_id = 0
    for dt in dates:
        for _ in range(1000):
            event_id += 1
            writer.writerow([
                event_id,
                random.randint(1, 500),
                random.choice(event_types),
                random.choice(products),
                f"{random.uniform(1, 2000):.2f}",
                random.randint(1, 5),
                dt,
            ])
PY

echo "Загрузка данных в HDFS: ${HDFS_INPUT}"
hdfs dfs -mkdir -p "$HDFS_INPUT"
hdfs dfs -put -f "$CSV" "$HDFS_INPUT/"

hdfs dfs -ls "$HDFS_INPUT"
echo "Первые строки данных:"
hdfs dfs -cat "${HDFS_INPUT}/events.csv" | awk 'NR <= 5 {print}'

echo "Загрузка данных завершена"
