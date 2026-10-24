import os

from pyspark.sql import SparkSession
from pyspark.sql import functions as F
from pyspark.sql.types import (
    IntegerType,
    StringType,
    StructField,
    StructType,
)

HDFS_INPUT = os.environ.get("HDFS_INPUT", "/user/team/hw4/input")
DB_NAME = os.environ.get("DB_NAME", "hw4")
TABLE_NAME = os.environ.get("TABLE_NAME", "events_summary")

spark = (
    SparkSession.builder.appName("hw4-events-etl")
    .enableHiveSupport()
    .getOrCreate()
)
spark.sparkContext.setLogLevel("WARN")
print(f"YARN application ID: {spark.sparkContext.applicationId}", flush=True)
print(f"Spark master: {spark.sparkContext.master}", flush=True)

schema = StructType(
    [
        StructField("event_id", IntegerType(), True),
        StructField("user_id", IntegerType(), True),
        StructField("event_type", StringType(), True),
        StructField("product", StringType(), True),
        StructField("price", StringType(), True),
        StructField("quantity", StringType(), True),
        StructField("dt", StringType(), True),
    ]
)

raw = spark.read.option("header", "true").schema(schema).csv(HDFS_INPUT)

events = (
    raw.withColumn("price", F.col("price").cast("double"))
    .withColumn("quantity", F.col("quantity").cast("int"))
    .filter((F.col("price") > 0) & (F.col("quantity") > 0))
    .withColumn("amount", F.round(F.col("price") * F.col("quantity"), 2))
)

summary = (
    events.groupBy("dt", "event_type")
    .agg(
        F.count("*").alias("events_cnt"),
        F.countDistinct("user_id").alias("unique_users"),
        F.round(F.sum("amount"), 2).alias("total_amount"),
        F.round(F.avg("price"), 2).alias("avg_price"),
    )
    .orderBy("dt", "event_type")
)

spark.sql(f"CREATE DATABASE IF NOT EXISTS {DB_NAME}")

(
    summary.write.mode("overwrite")
    .partitionBy("dt")
    .saveAsTable(f"{DB_NAME}.{TABLE_NAME}")
)

print("=== Преобразованные данные ===")
summary.show(20, truncate=False)

print(f"=== Таблица {DB_NAME}.{TABLE_NAME} ===")
spark.sql(f"SHOW PARTITIONS {DB_NAME}.{TABLE_NAME}").show(truncate=False)
spark.sql(f"SELECT * FROM {DB_NAME}.{TABLE_NAME} LIMIT 10").show(truncate=False)

spark.stop()
