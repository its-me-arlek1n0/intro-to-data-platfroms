#!/usr/bin/env bash
set -euo pipefail
cd "$(dirname "$0")"
source env.sh

if [ ! -f "/tmp/${HADOOP_TARBALL}" ]; then
  curl -fSL --retry 3 -o "/tmp/${HADOOP_TARBALL}" "${HADOOP_URL}"
fi

for node in $ALL_NODES; do
  echo "$node"
  scp $SSH_OPTS -q "/tmp/${HADOOP_TARBALL}" "${SSH_USER}@${node}:/tmp/" || true
  scp $SSH_OPTS -q scripts/01_install_node.sh "${SSH_USER}@${node}:/tmp/"
  $SSH "${SSH_USER}@${node}" "bash /tmp/01_install_node.sh /tmp/${HADOOP_TARBALL}"
  scp $SSH_OPTS -q scripts/02_configure_node.sh "${SSH_USER}@${node}:/tmp/"
  $SSH "${SSH_USER}@${node}" 'rm -rf /tmp/hadoop-config'
  scp $SSH_OPTS -q -r config "${SSH_USER}@${node}:/tmp/hadoop-config"
  $SSH "${SSH_USER}@${node}" 'bash /tmp/02_configure_node.sh'
done

bash scripts/03_format_namenode.sh
bash scripts/04_start_cluster.sh
bash scripts/06_check_cluster.sh
