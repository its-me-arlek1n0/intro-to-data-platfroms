#!/usr/bin/env bash

export SPARK_VERSION="3.5.9"
export SPARK_URL="https://archive.apache.org/dist/spark/spark-${SPARK_VERSION}/spark-${SPARK_VERSION}-bin-hadoop3.tgz"
export INSTALL_DIR="${HOME}/opt"
export SPARK_HOME="${INSTALL_DIR}/spark-${SPARK_VERSION}-bin-hadoop3"

export HADOOP_HOME="${HADOOP_HOME:-/opt/hadoop}"
export HADOOP_CONF_DIR="${HADOOP_HOME}/etc/hadoop"
export YARN_CONF_DIR="${HADOOP_HOME}/etc/hadoop"

export HW4_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
export HW4_LOGS="${HW4_DIR}/logs"

export HIVE_HOME="${HIVE_HOME:-${INSTALL_DIR}/apache-hive-4.0.0-alpha-2-bin}"
export METASTORE_HOST="${METASTORE_HOST:-$(hostname -f 2>/dev/null || hostname)}"
export METASTORE_PORT="9083"
export METASTORE_URI="thrift://${METASTORE_HOST}:${METASTORE_PORT}"
export HS2_PORT="10000"
export WAREHOUSE_DIR="/user/hive/warehouse"
export NN_HOST="team-11-nn"

export HDFS_INPUT="/user/team/hw4/input"
export DB_NAME="hw4"
export TABLE_NAME="events_summary"

export PYSPARK_PYTHON="python3"
export PYSPARK_DRIVER_PYTHON="python3"

export PATH="${SPARK_HOME}/bin:${HIVE_HOME}/bin:${HADOOP_HOME}/bin:${PATH}"
