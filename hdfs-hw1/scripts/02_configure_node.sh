#!/usr/bin/env bash
set -euo pipefail

HADOOP_HOME="/opt/hadoop"
CONF_DIR="${HADOOP_HOME}/etc/hadoop"
CONFIGS="${1:-/tmp/hadoop-config}"

cp "${CONFIGS}"/* "${CONF_DIR}/"

JAVA_HOME_DIR="$(dirname "$(dirname "$(readlink -f "$(command -v java)")")")"
sed -i '/^export JAVA_HOME=/d' "${CONF_DIR}/hadoop-env.sh"
echo "export JAVA_HOME=${JAVA_HOME_DIR}" >> "${CONF_DIR}/hadoop-env.sh"
