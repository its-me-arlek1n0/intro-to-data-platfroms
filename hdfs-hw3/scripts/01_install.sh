#!/usr/bin/env bash
set -euo pipefail
cd "$(dirname "$0")/.."
source ./env.sh

mkdir -p "$INSTALL_DIR" "$HIVE_LOGS"

echo "Установка PostgreSQL"
sudo apt-get update -qq
sudo apt-get install -y -qq postgresql gettext-base
sudo service postgresql start || true

sudo -u postgres psql -tc "SELECT 1 FROM pg_roles WHERE rolname='${DB_USER}'" | grep -q 1 || \
  sudo -u postgres psql -c "CREATE USER ${DB_USER} WITH PASSWORD '${DB_PASSWORD}';"
sudo -u postgres psql -tc "SELECT 1 FROM pg_database WHERE datname='${DB_NAME}'" | grep -q 1 || \
  sudo -u postgres createdb -O "${DB_USER}" "${DB_NAME}"

echo "Установка Hive ${HIVE_VERSION}"
if [ ! -d "$HIVE_HOME" ]; then
  wget -q "$HIVE_URL" -O /tmp/apache-hive-bin.tar.gz
  tar -xzf /tmp/apache-hive-bin.tar.gz -C "$INSTALL_DIR"
  rm -f /tmp/apache-hive-bin.tar.gz
fi

if ! ls "$HIVE_HOME"/lib/postgresql-*.jar >/dev/null 2>&1; then
  wget -q "$PG_JDBC_URL" -O "$HIVE_HOME/lib/postgresql-jdbc.jar"
fi

HADOOP_GUAVA=$(ls "$HADOOP_HOME"/share/hadoop/common/lib/guava-*.jar 2>/dev/null | sort -V | tail -1 || true)
if [ -n "$HADOOP_GUAVA" ]; then
  rm -f "$HIVE_HOME"/lib/guava-*.jar
  cp "$HADOOP_GUAVA" "$HIVE_HOME/lib/"
fi

echo "Проверка библиотеки Commons Collections для MapReduce"
test -f "$HIVE_HOME/lib/commons-collections-3.2.2.jar"

envsubst < config/hive-site.xml > "$HIVE_HOME/conf/hive-site.xml"

echo "Создание каталогов в HDFS"
hdfs dfs -mkdir -p "$WAREHOUSE_DIR"
hdfs dfs -chmod -R g+w "$WAREHOUSE_DIR"
hdfs dfs -mkdir -p /tmp
hdfs dfs -chmod 777 /tmp

echo "Инициализация схемы метастора"
if ! schematool -dbType postgres -info >/dev/null 2>&1; then
  schematool -dbType postgres -initSchema
fi
schematool -dbType postgres -info | grep -i version

echo "Установка завершена"
