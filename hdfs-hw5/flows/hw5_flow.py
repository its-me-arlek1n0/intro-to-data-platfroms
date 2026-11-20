import os
import re
import subprocess
import time

from prefect import flow, task

HW5_DIR = os.environ.get("HW5_DIR", os.path.expanduser("~/hw5"))
HDFS_INPUT = os.environ.get("HDFS_INPUT", "/user/team/hw5/input")
DB_NAME = os.environ.get("DB_NAME", "hw5")
TABLE_NAME = os.environ.get("TABLE_NAME", "events_summary")
HS2_PORT = os.environ.get("HS2_PORT", "10000")
WAREHOUSE_DIR = os.environ.get("WAREHOUSE_DIR", "/user/hive/warehouse")
SPARK_LOG = os.path.join(HW5_DIR, "logs", "spark_submit.log")


def run(cmd):
    return subprocess.run(
        cmd, shell=True, capture_output=True, text=True, executable="/bin/bash"
    )


@task
def check_hdfs_data():
    input_file = f"{HDFS_INPUT}/events.csv"

    r = run(f'hdfs dfs -test -s "{input_file}"')
    if r.returncode != 0:
        raise RuntimeError(
            f"Входной файл отсутствует, пуст или недоступен: {input_file}\n"
            f"{r.stderr}"
        )

    print(f"Входной файл найден и не пуст: {input_file}")


@task
def submit_spark_job():
    r = run(f"spark-submit --master yarn --deploy-mode client {HW5_DIR}/app/spark_job.py")
    with open(SPARK_LOG, "w") as f:
        f.write(r.stdout + r.stderr)
    print(r.stdout)
    if r.returncode != 0:
        print(r.stderr)
        raise RuntimeError("spark-submit завершился с ошибкой, см. logs/spark_submit.log")
    app_ids = re.findall(r"YARN application ID: (application_\d+_\d+)", r.stdout)
    if not app_ids:
        raise RuntimeError("Не удалось определить YARN application ID")
    return app_ids[-1]


@task
def check_yarn_status(app_id):
    for attempt in range(15):
        r = run(f"yarn application -status {app_id}")

        if r.returncode != 0:
            raise RuntimeError(
                f"Не удалось получить статус приложения {app_id}:\n"
                f"{r.stderr}"
            )

        state_match = re.search(
            r"^\s*State\s*:\s*(\S+)",
            r.stdout,
            re.MULTILINE,
        )
        final_match = re.search(
            r"^\s*Final-State\s*:\s*(\S+)",
            r.stdout,
            re.MULTILINE,
        )

        if not state_match or not final_match:
            raise RuntimeError(
                f"Не удалось разобрать статус приложения:\n{r.stdout}"
            )

        state = state_match.group(1)
        final_state = final_match.group(1)

        print(f"{app_id}: {state} / {final_state}")

        if state == "FINISHED" and final_state == "SUCCEEDED":
            print(r.stdout)
            return

        if state in ("FAILED", "KILLED") or final_state in ("FAILED", "KILLED"):
            raise RuntimeError(
                f"Приложение завершилось с ошибкой:\n{r.stdout}"
            )

        time.sleep(2)

    raise RuntimeError(
        f"Не удалось дождаться успешного завершения {app_id}"
    )


@task
def verify_table():
    hive_home = os.environ["HIVE_HOME"]
    beeline = os.path.join(hive_home, "bin", "beeline")

    sql = (
        f"SHOW TABLES IN {DB_NAME};"
        f"SHOW PARTITIONS {DB_NAME}.{TABLE_NAME};"
        f"SELECT * FROM {DB_NAME}.{TABLE_NAME} "
        f"ORDER BY dt, event_type LIMIT 12;"
        f"SELECT dt, SUM(total_amount) AS day_amount "
        f"FROM {DB_NAME}.{TABLE_NAME} "
        f"GROUP BY dt ORDER BY dt;"
    )

    r = run(
        f'"{beeline}" '
        f'-u "jdbc:hive2://localhost:{HS2_PORT}" '
        f'-e "{sql}"'
    )

    print(r.stdout)

    if r.returncode != 0:
        raise RuntimeError(
            f"Таблица не читается через Hive:\n{r.stderr}"
        )

    table_path = f"{WAREHOUSE_DIR}/{DB_NAME}.db/{TABLE_NAME}"
    r = run(f'hdfs dfs -ls "{table_path}"')

    if r.returncode != 0:
        raise RuntimeError(
            f"Не удалось проверить файлы таблицы в HDFS:\n{r.stderr}"
        )

    print("Файлы таблицы в HDFS:")
    print(r.stdout)


@flow(name="hw5-spark-etl", log_prints=True)
def hw5_pipeline():
    check_hdfs_data()
    app_id = submit_spark_job()
    check_yarn_status(app_id)
    verify_table()
    print("Поток обработки данных успешно завершён")


if __name__ == "__main__":
    hw5_pipeline()
