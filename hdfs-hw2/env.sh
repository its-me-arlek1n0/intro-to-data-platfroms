#!/usr/bin/env bash
source "$(dirname "${BASH_SOURCE[0]}")/../hdfs-hw1/env.sh"

EDGE_NODE="team-11-en"
RESOURCE_MANAGER="$NAMENODE"
HISTORY_SERVER="$NAMENODE"
NODE_MANAGERS="team-11-nn team-11-00 team-11-01"
HW2_HDFS_ROOT="/user/team/hdfs-hw2"

SSH_OPTS="-i $SSH_KEY -o BatchMode=yes -o StrictHostKeyChecking=yes -o ConnectTimeout=5"
SSH="ssh $SSH_OPTS"
export HADOOP_HOME
export HADOOP_CONF_DIR="$HADOOP_HOME/etc/hadoop"
export HADOOP_COMMON_HOME="$HADOOP_HOME" HADOOP_HDFS_HOME="$HADOOP_HOME"
export HADOOP_YARN_HOME="$HADOOP_HOME" HADOOP_MAPRED_HOME="$HADOOP_HOME"
export PATH="$HADOOP_HOME/bin:$PATH"

if [ "$(hostname -s)" != "$EDGE_NODE" ]; then
  echo "Запустите скрипт на $EDGE_NODE"
  exit 1
fi
