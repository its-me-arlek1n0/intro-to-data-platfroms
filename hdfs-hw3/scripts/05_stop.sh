#!/usr/bin/env bash
set -euo pipefail

pkill -f "proc_hiveserver2" 2>/dev/null && echo "Остановка HiveServer2 завершена" || echo "HiveServer2 не запущен"
pkill -f "proc_metastore" 2>/dev/null && echo "Остановка метастора завершена" || echo "Метастор не запущен"
