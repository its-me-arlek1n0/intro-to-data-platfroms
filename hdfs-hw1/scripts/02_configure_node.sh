#!/usr/bin/env bash
set -euo pipefail

HADOOP_HOME="/opt/hadoop"
CONF_DIR="${HADOOP_HOME}/etc/hadoop"
CONFIGS="${1:-/tmp/hadoop-config}"

JAVA_HOME_DIR="/usr/lib/jvm/java-11-openjdk-amd64"
test -x "$JAVA_HOME_DIR/bin/java"

cp "${CONFIGS}"/* "${CONF_DIR}/"
sed -i '/^export JAVA_HOME=/d' "${CONF_DIR}/hadoop-env.sh"
echo "export JAVA_HOME=${JAVA_HOME_DIR}" >> "${CONF_DIR}/hadoop-env.sh"
