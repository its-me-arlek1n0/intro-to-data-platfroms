#!/usr/bin/env bash
set -uo pipefail
cd "$(dirname "$0")/.."
source env.sh

for dn in $DATANODES; do
  $SSH "${SSH_USER}@${dn}" 'source /etc/profile.d/hadoop.sh && hdfs --daemon stop datanode'
done

$SSH "${SSH_USER}@${SECONDARY_NN}" 'source /etc/profile.d/hadoop.sh && hdfs --daemon stop secondarynamenode'
$SSH "${SSH_USER}@${NAMENODE}" 'source /etc/profile.d/hadoop.sh && hdfs --daemon stop namenode'
echo "остановлено"
