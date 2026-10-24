# ДЗ 4 — Apache Spark под управлением YARN: чтение, трансформация и запись данных в HDFS

В рамках домашнего задания автоматизирован запуск ETL-приложения Apache Spark на кластере YARN. Приложение читает предварительно загруженные в HDFS данные, выполняет несколько трансформаций (преобразование типов, фильтрация, добавление вычисляемого столбца, агрегация) и сохраняет результат в виде партиционированной таблицы. Корректность результата проверяется чтением таблицы стандартным клиентом Hive (Beeline).

Используется инфраструктура из предыдущих заданий: HDFS из первого ДЗ, YARN из второго ДЗ, Hive Metastore и HiveServer2 из третьего ДЗ. Все управляющие команды запускаются с edge-ноды `team-11-en`.

**Используемые версии:**

- Spark 3.5.9 (сборка для Hadoop 3);
- Hadoop 3.4.2;
- Hive 4.0.0-alpha-2;
- Java 11;
- Python 3.12.

## Архитектура кластера

| Узел | IP | Роль |
|---|---|---|
| `team-11-en` | `10.11.0.10` | Edge Node, Spark driver, Hive Metastore, HiveServer2, клиент Beeline |
| `team-11-nn` | `10.11.0.11` | NameNode, DataNode, ResourceManager, NodeManager, JobHistoryServer |
| `team-11-00` | `10.11.0.12` | DataNode, NodeManager |
| `team-11-01` | `10.11.0.13` | DataNode, NodeManager |

Spark-приложение запускается в режиме `client`: драйвер работает на edge-ноде, а исполнители (executors) — в контейнерах YARN на узлах кластера. Для сохранения данных как таблицы Spark подключается к Hive Metastore из третьего ДЗ по протоколу Thrift и записывает файлы таблицы в общее хранилище HDFS, поэтому таблица сразу доступна для чтения через HiveServer2.

| Сервис | Адрес | Назначение |
|---|---|---|
| HDFS | `hdfs://team-11-nn:8020` | Хранение входных данных и файлов таблиц |
| YARN ResourceManager | `team-11-nn:8032` | Запуск и управление Spark-приложением |
| Hive Metastore | `thrift://team-11-en:9083` | Регистрация таблицы Spark'ом |
| HiveServer2 | `jdbc:hive2://team-11-en:10000` | Проверка чтения таблицы клиентом Hive |

---

# Структура проекта

```text
hdfs-hw4/
├── README.md
├── .gitignore
├── env.sh
│
├── config/
│   └── spark-defaults.conf
│
├── app/
│   └── spark_job.py
│
├── scripts/
│   ├── 01_install_spark.sh
│   ├── 02_prepare_data.sh
│   ├── 03_run_spark.sh
│   ├── 04_check_hive.sh
│   └── 05_cleanup.sh
│
├── logs/
│   └── spark_submit.log
│
└── reports/
    ├── prepare-data.txt
    ├── run-spark.txt
    ├── yarn-status.txt
    ├── check-hive.txt
    ├── hive-result.txt
    ├── hive-verification.log
    ├── hdfs-files.txt
    └── verification.json
```

Каталог `logs/` и файлы в нём создаются при выполнении скриптов.

---

# Назначение файлов

## `env.sh`

Содержит общие параметры установки и подключения:

- версию Spark и адрес архива;
- каталог установки Spark;
- пути к Hadoop и его конфигурации (`HADOOP_CONF_DIR`, `YARN_CONF_DIR`);
- адрес Hive Metastore и каталог хранения таблиц в HDFS;
- путь к входным данным в HDFS, имя базы и таблицы результата.

Остальные скрипты подключают параметры командой:

```bash
source ./env.sh
```

По умолчанию Spark устанавливается в `~/opt/spark-3.5.9-bin-hadoop3`. Путь `HW4_DIR` определяется по расположению `env.sh`, поэтому логи записываются в папку `logs/` рядом с проектом независимо от имени его каталога.

## `config/spark-defaults.conf`

Шаблон конфигурации Spark:

- `spark.master=yarn`, режим развертывания `client` — запуск под управлением YARN;
- ресурсы исполнителей (2 экземпляра по 1 ядру и 512 МБ) с учётом ограничений кластера (1536 МБ на NodeManager);
- `spark.hadoop.hive.metastore.uris` — адрес Hive Metastore для регистрации таблицы;
- `spark.sql.warehouse.dir` — общее с Hive хранилище таблиц в HDFS.

Значения `${METASTORE_URI}`, `${NN_HOST}`, `${WAREHOUSE_DIR}` подставляются из `env.sh` скриптом `scripts/01_install_spark.sh` командой `envsubst`.

## `app/spark_job.py`

ETL-приложение на PySpark:

1. Создаёт сессию Spark с поддержкой Hive (`enableHiveSupport`), мастер — YARN;
2. Читает CSV-файл из HDFS (`/user/team/hw4/input/events.csv`) с явной схемой;
3. Применяет трансформации:
   - приведение типов столбцов `price` → double, `quantity` → int;
   - фильтрацию некорректных строк (`price > 0`, `quantity > 0`);
   - добавление вычисляемого столбца `amount = price * quantity`;
   - агрегацию по дате и типу события: число событий, число уникальных пользователей, сумма и средняя цена;
4. Создаёт базу `hw4` и сохраняет результат как таблицу `hw4.events_summary` с партиционированием по столбцу `dt` (`saveAsTable` + `partitionBy`);
5. Выводит преобразованные данные, список партиций и пример строк.

## Скрипты

- `scripts/01_install_spark.sh` — скачивает и распаковывает Spark в `~/opt`, формирует `spark-defaults.conf` из шаблона;
- `scripts/02_prepare_data.sh` — генерирует CSV с событиями за 4 дня (4000 строк) и загружает его в HDFS;
- `scripts/03_run_spark.sh` — запускает `spark-submit --master yarn`, сохраняет лог в `logs/spark_submit.log`, получает ID текущего приложения из его вывода и проверяет состояние `FINISHED` / `SUCCEEDED`;
- `scripts/04_check_hive.sh` — проверяет чтение созданной таблицы клиентом Hive из `$HIVE_HOME/bin/beeline`: список таблиц, описание, партиции, выборку и агрегацию, а также расположение партиций в HDFS;
- `scripts/05_cleanup.sh` — удаляет таблицу и входные данные (необязательный шаг).

---

# Порядок запуска

Все команды выполняются на edge-ноде `team-11-en`. Перед запуском должны работать HDFS, YARN, Hive Metastore и HiveServer2 (см. ДЗ 1–3).

```bash
cd ~/github-repo/hdfs-hw4

# 1. Установка Spark
bash scripts/01_install_spark.sh

# 2. Генерация и загрузка входных данных в HDFS
bash scripts/02_prepare_data.sh

# 3. Запуск Spark-приложения на YARN
bash scripts/03_run_spark.sh

# 4. Проверка чтения таблицы через Hive
bash scripts/04_check_hive.sh
```

Очистка — отдельный необязательный шаг. Она удаляет таблицу и входные данные, поэтому перед сдачей и демонстрацией результата её выполнять не нужно. При необходимости удалить результат:

```bash
bash scripts/05_cleanup.sh
```

---

# Проверка результата

1. **Приложение выполнено на YARN.** В конце `scripts/03_run_spark.sh` выводится статус приложения: `FINISHED` / `SUCCEEDED`. Список приложений также доступен командой `yarn application -list -appStates ALL`, веб-интерфейс ResourceManager — на `team-11-nn:8088`.

2. **Таблица создана и партиционирована.** Spark сохраняет результат в `/user/hive/warehouse/hw4.db/events_summary` с каталогами партиций `dt=2024-02-01` … `dt=2024-02-04`:

   ```bash
   hdfs dfs -ls /user/hive/warehouse/hw4.db/events_summary
   ```

3. **Таблица читается стандартным клиентом Hive.** `scripts/04_check_hive.sh` выполняет через Beeline:

   ```sql
   SHOW TABLES IN hw4;
   SHOW PARTITIONS hw4.events_summary;
   SELECT * FROM hw4.events_summary ORDER BY dt, event_type LIMIT 12;
   SELECT dt, SUM(total_amount) AS day_amount
   FROM hw4.events_summary GROUP BY dt ORDER BY dt;
   ```

   Запросы успешно выполняются, включая запуск заданий MapReduce на YARN для агрегации.

---

# Как это работает

1. `02_prepare_data.sh` формирует CSV-файл с событиями пользователей (`event_id`, `user_id`, `event_type`, `product`, `price`, `quantity`, `dt`) и копирует его в HDFS.
2. `spark-submit --master yarn` отправляет приложение в ResourceManager; YARN выделяет контейнеры на NodeManager'ах и запускает в них исполнителей Spark.
3. Приложение читает CSV блоками из HDFS, применяет трансформации и агрегацию распределённо на исполнителях.
4. Результат записывается в формате Parquet в хранилище Hive с разбиением по партициям `dt`, а метаданные таблицы (схема, партиции, расположение) регистрируются в Hive Metastore.
5. Поскольку используются общий Metastore и общий каталог хранилища, таблица немедленно доступна HiveServer2: клиент Beeline читает её как обычную Hive-таблицу.


# Результаты проверок

Каталог `reports/` содержит результаты последнего проверочного запуска:

- `prepare-data.txt` — загрузка исходного CSV в HDFS;
- `run-spark.txt` — вывод запуска Spark;
- `yarn-status.txt` — итоговый статус именно этого приложения YARN;
- `check-hive.txt` — чтение таблицы клиентом Hive;
- `verification.json` — независимое сравнение таблицы с исходным CSV, включая число строк, партиции, суммы и средние значения.

Входные данные и итоговая таблица после проверки сохраняются в HDFS.
