# ДЗ 2 — YARN и веб-интерфейсы Hadoop

Продолжение (../hdfs-hw1/README.md). Поверх готовой HDFS поднимаем ResourceManager, 3 NodeManager и JobHistoryServer, веб-интерфейсы публикуем через SSH-туннель с edge-ноды. Hadoop уже установлен — ничего переустанавливать и форматировать не нужно.

Все кластеры запускаются на edge под пользователем `team`.

## Как запускать

Нужна работающая HDFS из первого ДЗ. Дальше:

```bash
cd ~/github-repo/hdfs-hw2
bash deploy_yarn.sh
```

Скрипт по порядку делает всё сам:

1. `01_configure_yarn.sh` — копирует конфиги из `config/` (`yarn-site.xml`, `mapred-site.xml`, `hw2-env.sh`) на все узлы, создаёт каталоги в HDFS под логи и историю.
2. `02_start_yarn.sh` и `03_start_historyserver.sh` — стартуют демоны по SSH (`yarn --daemon start`, `mapred --daemon start`).
3. `04_publish_web.sh` — создаёт systemd user-сервис `hdfs-hw2-web.service`, который держит SSH-туннель до веб-интерфейсов. Список интерфейсов и портов — в `config/web-interfaces.tsv`.
4. `05_check_yarn.sh` — проверка: 3 NodeManager в RUNNING, HDFS здорова, все 10 веб-страниц отвечают.

Остановить YARN: `bash scripts/06_stop_yarn.sh --confirm` (HDFS и туннель не трогает).

## Что лежит в `config/`

Здесь лежат готовые конфиги и таблица веб-интерфейсов, которые `scripts/01_configure_yarn.sh` (запускаемый из `deploy_yarn.sh`) раскидывает по узлам — сами скрипты их не создают, а только читают. `yarn-site.xml` — где запускать ResourceManager и NodeManager, сколько памяти и ядер давать каждому узлу, куда складывать логи и как их потом показывать в JobHistoryServer. `mapred-site.xml` — что MapReduce-задачи должны выполняться на YARN, а не локально, где искать JobHistoryServer и куда в HDFS складывать staging и историю. `hw2-env.sh` — общие пути Hadoop и ограничения памяти для демонов, подключается на каждом узле. `JAVA_HOME` задаётся в `hadoop-env.sh` при настройке первого ДЗ; используется Java 11. `resource-types.xml` — описание нестандартных ресурсов (GPU/FPGA); если их нет, файл пустой. `web-interfaces.tsv` — простая таблица «какой веб-интерфейс на каком узле и порту», по ней `scripts/04_publish_web.sh` поднимает туннели, а `scripts/05_check_yarn.sh` проверяет, что все страницы открываются.

## Откуда что берётся

- Имена узлов, SSH-ключ, путь Hadoop — из `../hdfs-hw1/env.sh`.
- Настройки YARN и MapReduce — из `config/yarn-site.xml` и `config/mapred-site.xml` этого репозитория.
- Результаты проверок и данные WordCount — в HDFS: `/user/team/hdfs-hw2/...` (не на локальном диске, смотреть через `hdfs dfs -ls/-cat`).
- Логи демонов — в `/opt/hadoop/logs` на соответствующем узле.

## Веб-интерфейсы со своего компьютера

Внешний адрес edge — `111.88.130.12`, нужен свой SSH-ключ. Из папки `hdfs-hw2`:

```bash
bash client/open_web_tunnel.sh                    # Linux/macOS
powershell -ExecutionPolicy Bypass -File .\client\Open-HadoopWeb.ps1   # Windows
```

Терминал не закрывать. Дальше в браузере: NameNode — `127.0.0.1:9870`, ResourceManager — `127.0.0.1:8088/cluster`, JobHistoryServer — `127.0.0.1:19888/jobhistory`, NodeManager — `127.0.0.1:18042-18044/node`, DataNode — `127.0.0.1:19864-19866/datanode.html`.

## Тест MapReduce

```bash
bash scripts/07_check_mapreduce.sh
```

Гоняет пример WordCount на YARN. Результат каждого запуска — в HDFS: `hdfs://team-11-nn:8020/user/team/hdfs-hw2/checks/<время>-<pid>/output` (скрипт печатает полный путь). 
