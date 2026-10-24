#!/usr/bin/env bash
set -euo pipefail
cd "$(dirname "$0")/.."
source ./env.sh

echo "Список таблиц базы ${DB_NAME}:"
"$HIVE_HOME/bin/beeline" -u "jdbc:hive2://localhost:${HS2_PORT}" \
  -e "SHOW TABLES IN ${DB_NAME};"

echo "Описание таблицы ${DB_NAME}.${TABLE_NAME}:"
"$HIVE_HOME/bin/beeline" -u "jdbc:hive2://localhost:${HS2_PORT}" \
  -e "DESCRIBE FORMATTED ${DB_NAME}.${TABLE_NAME};" | grep -E "col_name|# Partition|dt|event_type|events_cnt|unique_users|total_amount|avg_price|Location|InputFormat" | head -20

echo "Партиции таблицы:"
"$HIVE_HOME/bin/beeline" -u "jdbc:hive2://localhost:${HS2_PORT}" \
  -e "SHOW PARTITIONS ${DB_NAME}.${TABLE_NAME};"

echo "Чтение данных через Hive:"
"$HIVE_HOME/bin/beeline" -u "jdbc:hive2://localhost:${HS2_PORT}" \
  -e "SELECT * FROM ${DB_NAME}.${TABLE_NAME} ORDER BY dt, event_type LIMIT 12;"

echo "Агрегация через Hive поверх созданной таблицы:"
"$HIVE_HOME/bin/beeline" -u "jdbc:hive2://localhost:${HS2_PORT}" \
  -e "SELECT dt, SUM(total_amount) AS day_amount FROM ${DB_NAME}.${TABLE_NAME} GROUP BY dt ORDER BY dt;"

echo "Расположение партиций в HDFS:"
hdfs dfs -ls "${WAREHOUSE_DIR}/${DB_NAME}.db/${TABLE_NAME}"

echo "Проверка чтения через Hive завершена"
