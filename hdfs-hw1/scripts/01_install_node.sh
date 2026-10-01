#!/usr/bin/env bash
set -euo pipefail

HADOOP_VERSION="3.4.2"
HADOOP_HOME="/opt/hadoop"
DATA_DIR="/opt/hadoop/data"
TARBALL_LOCAL="${1:-/tmp/hadoop-${HADOOP_VERSION}.tar.gz}"

if ! command -v java >/dev/null 2>&1; then
  sudo apt-get update -qq
  sudo apt-get install -y -qq openjdk-11-jre-headless
fi

if [ ! -d "${HADOOP_HOME}" ]; then
  sudo tar -xzf "${TARBALL_LOCAL}" -C /opt
  sudo ln -sfn "/opt/hadoop-${HADOOP_VERSION}" "${HADOOP_HOME}"
  sudo chown -R team:team "/opt/hadoop-${HADOOP_VERSION}"
fi

sudo mkdir -p "${DATA_DIR}/namenode" "${DATA_DIR}/datanode" /opt/hadoop/logs
sudo chown -R team:team "${DATA_DIR}" /opt/hadoop/logs

JAVA_HOME_DIR="$(dirname "$(dirname "$(readlink -f "$(command -v java)")")")"
sudo tee /etc/profile.d/hadoop.sh >/dev/null <<EOF
export JAVA_HOME=${JAVA_HOME_DIR}
export HADOOP_HOME=${HADOOP_HOME}
export PATH=\$PATH:${HADOOP_HOME}/bin:${HADOOP_HOME}/sbin
EOF

HOST_SHORT="$(hostname -s)"
HOST_IP="$(hostname -I | awk '{print $1}')"
sudo sed -i "/^127\.0\.1\.1/s/[[:space:]]${HOST_SHORT}\$//" /etc/hosts
if ! grep -qE "^${HOST_IP}[[:space:]]+${HOST_SHORT}\b" /etc/hosts; then
  echo "${HOST_IP} ${HOST_SHORT}" | sudo tee -a /etc/hosts >/dev/null
fi

echo "установлено"
