#!/usr/bin/env bash

export HADOOP_HOME="${HADOOP_HOME:-/opt/hadoop}"
export HADOOP_CONF_DIR="${HADOOP_HOME}/etc/hadoop"
export YARN_CONF_DIR="${HADOOP_HOME}/etc/hadoop"

export INSTALL_DIR="${HOME}/opt"
export SPARK_HOME="${INSTALL_DIR}/spark-3.5.9-bin-hadoop3"
export HIVE_HOME="${HIVE_HOME:-${INSTALL_DIR}/apache-hive-4.0.0-alpha-2-bin}"

export HW5_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
export HW5_LOGS="${HW5_DIR}/logs"
export PREFECT_VENV="${HW5_DIR}/venv"

export NN_HOST="team-11-nn"
export HDFS_INPUT="/user/team/hw5/input"
export WAREHOUSE_DIR="/user/hive/warehouse"
export DB_NAME="hw5"
export TABLE_NAME="events_summary"
export HS2_PORT="10000"

export PYSPARK_PYTHON="python3"
export PYSPARK_DRIVER_PYTHON="python3"

export PATH="${SPARK_HOME}/bin:${HIVE_HOME}/bin:${HADOOP_HOME}/bin:${PATH}"
