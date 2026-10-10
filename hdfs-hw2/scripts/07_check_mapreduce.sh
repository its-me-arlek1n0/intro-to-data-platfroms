#!/usr/bin/env bash
set -euo pipefail
cd "$(dirname "$0")/.."
source env.sh

# Необязательная проверка вычислений на YARN. Каждый запуск — в новом каталоге
dir="$HW2_HDFS_ROOT/checks/$(date -u +%Y%m%dT%H%M%S)-$$"
input=$(mktemp)
trap 'rm -f "$input"' EXIT
printf 'hadoop yarn hadoop\nyarn hdfs\n' > "$input"
hdfs dfs -mkdir -p "$dir"
hdfs dfs -put "$input" "$dir/input.txt"

timeout --foreground --kill-after=5s 240 \
  hadoop jar "$HADOOP_HOME/share/hadoop/mapreduce/hadoop-mapreduce-examples-3.4.2.jar" \
  wordcount "$dir/input.txt" "$dir/output"
result=$(hdfs dfs -cat "$dir/output/part-r-*")
echo "$result"
expected=$(printf 'hadoop\t2\nhdfs\t1\nyarn\t2')
test "$result" = "$expected"
hdfs dfs -test -e "$dir/output/_SUCCESS"
fs_uri=$(hdfs getconf -confKey fs.defaultFS)
echo "WordCount выполнен; результаты сохранены в HDFS: $fs_uri$dir/output"
echo "Посмотреть результат: hdfs dfs -cat $dir/output/part-r-*"
echo "Историю задания можно посмотреть в JobHistoryServer."
