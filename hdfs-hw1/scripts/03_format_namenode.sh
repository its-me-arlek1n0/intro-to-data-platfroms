#!/usr/bin/env bash
set -euo pipefail
cd "$(dirname "$0")/.."
source env.sh

$SSH "${SSH_USER}@${NAMENODE}" '
  source /etc/profile.d/hadoop.sh
  if [ -n "$(ls -A /opt/hadoop/data/namenode 2>/dev/null)" ]; then
    echo "namenode уже отформатирован, выходим"
    exit 1
  fi
  hdfs namenode -format -force -nonInteractive
'
echo "отформатировано"
