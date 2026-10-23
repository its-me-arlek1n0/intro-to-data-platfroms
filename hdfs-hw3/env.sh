#!/usr/bin/env bash

export HIVE_VERSION="4.0.0-alpha-2"
export HIVE_URL="https://archive.apache.org/dist/hive/hive-${HIVE_VERSION}/apache-hive-${HIVE_VERSION}-bin.tar.gz"
export INSTALL_DIR="${HOME}/opt"
export HIVE_HOME="${INSTALL_DIR}/apache-hive-${HIVE_VERSION}-bin"
export HIVE_LOGS="${HOME}/hw3/logs"
export HADOOP_HOME="${HADOOP_HOME:-/opt/hadoop}"

export DB_HOST="localhost"
export DB_PORT="5432"
export DB_NAME="metastore"
export DB_USER="hive"
export DB_PASSWORD="hive123"
export PG_JDBC_URL="https://jdbc.postgresql.org/download/postgresql-42.7.4.jar"

export METASTORE_HOST="${METASTORE_HOST:-$(hostname -f 2>/dev/null || hostname)}"
export METASTORE_PORT="9083"
export HS2_PORT="10000"
export WAREHOUSE_DIR="/user/hive/warehouse"

export PATH="${HIVE_HOME}/bin:${HADOOP_HOME}/bin:${PATH}"
