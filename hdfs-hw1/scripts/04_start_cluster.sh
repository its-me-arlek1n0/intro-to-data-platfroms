#!/usr/bin/env bash
set -euo pipefail
cd "$(dirname "$0")/.."
source env.sh

$SSH "${SSH_USER}@${NAMENODE}" 'source /etc/profile.d/hadoop.sh && hdfs --daemon start namenode'
$SSH "${SSH_USER}@${SECONDARY_NN}" 'source /etc/profile.d/hadoop.sh && hdfs --daemon start secondarynamenode'

for dn in $DATANODES; do
  $SSH "${SSH_USER}@${dn}" 'source /etc/profile.d/hadoop.sh && hdfs --daemon start datanode'
done

sleep 15
echo "запущено"
