#!/usr/bin/env bash
set -euo pipefail
cd "$(dirname "$0")/.."
source ./env.sh

mkdir -p "$HW4_LOGS"

if [ ! -d "$SPARK_HOME" ]; then
  ARCHIVE="/tmp/spark-${SPARK_VERSION}-bin-hadoop3.tgz"
  if [ ! -f "$ARCHIVE" ]; then
    echo "Скачивание Spark ${SPARK_VERSION}..."
    curl -fL --retry 3 -o "$ARCHIVE" "$SPARK_URL"
  fi
  echo "Распаковка архива в ${INSTALL_DIR}..."
  mkdir -p "$INSTALL_DIR"
  tar -xzf "$ARCHIVE" -C "$INSTALL_DIR"
else
  echo "Spark уже установлен в ${SPARK_HOME}"
fi

echo "Формирование конфигурации spark-defaults.conf..."
envsubst < config/spark-defaults.conf > "${SPARK_HOME}/conf/spark-defaults.conf"

if [ -f "${SPARK_HOME}/conf/log4j2.properties.template" ] && [ ! -f "${SPARK_HOME}/conf/log4j2.properties" ]; then
  cp "${SPARK_HOME}/conf/log4j2.properties.template" "${SPARK_HOME}/conf/log4j2.properties"
  sed -i 's/^rootLogger.level = info/rootLogger.level = warn/' "${SPARK_HOME}/conf/log4j2.properties"
fi

"${SPARK_HOME}/bin/spark-submit" --version 2>&1 | grep -E "version|Using" | head -5
echo "Установка Spark завершена"
