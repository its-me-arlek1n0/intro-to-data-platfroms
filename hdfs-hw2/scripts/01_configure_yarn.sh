#!/usr/bin/env bash
set -euo pipefail
cd "$(dirname "$0")/.."
source env.sh

# Сначала проверяем все узлы. Не заменяем конфиги работающих служб.
for node in $ALL_NODES; do
  $SSH "$SSH_USER@$node" '
    set -e
    test -x /opt/hadoop/bin/yarn
    test -w /opt/hadoop/etc/hadoop
    mkdir -p /tmp/hdfs-hw2-config
  '
  scp $SSH_OPTS -q config/yarn-site.xml config/mapred-site.xml config/hw2-env.sh config/resource-types.xml \
    "$SSH_USER@$node:/tmp/hdfs-hw2-config/"
  $SSH "$SSH_USER@$node" '
    set -e
    changed=0
    for file in yarn-site.xml mapred-site.xml hw2-env.sh resource-types.xml; do
      cmp -s "/tmp/hdfs-hw2-config/$file" "/opt/hadoop/etc/hadoop/$file" || changed=1
    done
    # [o] позволяет pgrep не находить собственную команду проверки.
    if [ "$changed" -eq 1 ] && pgrep -f "[o]rg.apache.hadoop.*(ResourceManager|NodeManager|JobHistoryServer)" >/dev/null; then
      echo "Конфиги изменились, а YARN или JobHistoryServer работают. Сначала согласуйте их остановку."
      exit 1
    fi
  '
done

# Теперь сохраняем старые настройки и устанавливаем только конфиги второго ДЗ.
for node in $ALL_NODES; do
  $SSH "$SSH_USER@$node" '
    set -e
    cd /opt/hadoop/etc/hadoop
    for file in yarn-site.xml mapred-site.xml hw2-env.sh resource-types.xml; do
      if ! cmp -s "/tmp/hdfs-hw2-config/$file" "$file"; then
        cp "/tmp/hdfs-hw2-config/$file" "$file.new"
        mv "$file.new" "$file"
      fi
    done
    for file in yarn-env.sh mapred-env.sh; do
      grep -qx "source /opt/hadoop/etc/hadoop/hw2-env.sh" "$file" || \
        echo "source /opt/hadoop/etc/hadoop/hw2-env.sh" >> "$file"
    done
    mkdir -p /opt/hadoop/data/yarn/local /opt/hadoop/data/yarn/logs
    echo "Конфиги проверены и установлены"
  '
done

for dir in "$HW2_HDFS_ROOT" "$HW2_HDFS_ROOT/history" "$HW2_HDFS_ROOT/history/tmp" \
  "$HW2_HDFS_ROOT/history/done" "$HW2_HDFS_ROOT/logs" "$HW2_HDFS_ROOT/staging"; do
  if ! hdfs dfs -test -d "$dir"; then
    hdfs dfs -mkdir -p "$dir"
    hdfs dfs -chmod 700 "$dir"
  fi
done
