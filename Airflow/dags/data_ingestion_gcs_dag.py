import os
import logging
import zipfile
from datetime import timedelta

from airflow import DAG
from airflow.utils.dates import days_ago
from airflow.operators.bash import BashOperator
from airflow.operators.python import PythonOperator
from airflow.providers.google.cloud.operators.bigquery import BigQueryCreateExternalTableOperator
from google.cloud import storage
import pyarrow.csv as pv
import pyarrow.parquet as pq
import pyarrow as pa

# Google Cloud Storage and BigQuery settings
PROJECT_ID = os.environ.get("GCP_PROJECT_ID")
BUCKET = os.environ.get("GCP_GCS_BUCKET")
BIGQUERY_DATASET = os.environ.get("BIGQUERY_DATASET", 'Indego_project')
path_to_local_home = os.environ.get("AIRFLOW_HOME", "/opt/airflow/")

# Define specific files to process
FILES = [
    {"year": 2024, "quarter": "q4", "url": "https://www.rideindego.com/wp-content/uploads/2025/01/indego-trips-2024-q4.zip"},
    {"year": 2024, "quarter": "q3", "url": "https://www.rideindego.com/wp-content/uploads/2024/10/indego-trips-2024-q3.zip"},
    {"year": 2024, "quarter": "q2", "url": "https://www.rideindego.com/wp-content/uploads/2024/07/indego-trips-2024-q2.zip"},
    {"year": 2024, "quarter": "q1", "url": "https://www.rideindego.com/wp-content/uploads/2024/04/indego-trips-2024-q1.zip"},
    {"year": 2023, "quarter": "q4", "url": "https://www.rideindego.com/wp-content/uploads/2024/01/indego-trips-2023-q4.zip"},
    {"year": 2023, "quarter": "q3", "url": "https://www.rideindego.com/wp-content/uploads/2023/10/indego-trips-2023-q3.zip"},
    {"year": 2023, "quarter": "q2", "url": "https://www.rideindego.com/wp-content/uploads/2023/07/indego-trips-2023-q2.zip"},
    {"year": 2023, "quarter": "q1", "url": "https://www.rideindego.com/wp-content/uploads/2023/04/indego-trips-2023-q1.zip"}
]

# Define default_args for the DAG
default_args = {
    "owner": "airflow",
    "start_date": days_ago(1),
    "depends_on_past": False,
    "retries": 1,
    "retry_delay": timedelta(minutes=5),
}

def format_to_parquet(zip_file, year, quarter):
    """Convert CSVs in ZIP archive to Parquet, adding year and quarter columns."""
    if not zip_file.endswith('.zip'):
        logging.error("Can only accept ZIP files containing CSV files")
        return
    
    if not os.path.exists(zip_file):
        logging.error(f"File not found: {zip_file}")
        return

    try:
        with zipfile.ZipFile(zip_file, 'r') as z:
            csv_files = [f for f in z.namelist() if f.endswith('.csv')]
            if not csv_files:
                logging.error("No CSV files found in the ZIP archive")
                return
            
            for csv_file in csv_files:
                with z.open(csv_file) as f:
                    table = pv.read_csv(f)
                    table = table.append_column("year", pa.array([year] * table.num_rows))
                    table = table.append_column("quarter", pa.array([quarter] * table.num_rows))
                    parquet_filename = zip_file.replace('.zip', '.parquet')
                    pq.write_table(table, parquet_filename)
                    logging.info(f"Converted {csv_file} to {parquet_filename}")
    except zipfile.BadZipFile:
        logging.error(f"Invalid ZIP file: {zip_file}")
        return


def upload_to_gcs(bucket, object_name, local_file):
    """Uploads file to GCS."""
    storage.blob._MAX_MULTIPART_SIZE = 5 * 1024 * 1024  # 5MB
    storage.blob._DEFAULT_CHUNKSIZE = 5 * 1024 * 1024  # 5MB
    
    client = storage.Client()
    bucket = client.bucket(bucket)
    blob = bucket.blob(object_name)
    blob.upload_from_filename(local_file)
    logging.info(f"Uploaded {local_file} to gs://{bucket}/{object_name}")


def merge_all_trips():
    """Merge all trip Parquet files into a single Parquet file."""
    tables = []
    expected_schema = pa.schema([
        ("trip_id", pa.int64()),
        ("duration", pa.int64()),
        ("start_time", pa.string()),
        ("end_time", pa.string()),
        ("start_station", pa.int64()),
        ("start_lat", pa.float64()),
        ("start_lon", pa.float64()),
        ("end_station", pa.int64()),
        ("end_lat", pa.float64()),
        ("end_lon", pa.float64()),
        ("bike_id", pa.string()),  # Ensure bike_id is consistently a string
        ("plan_duration", pa.int64()),
        ("trip_route_category", pa.string()),
        ("passholder_type", pa.string()),
        ("bike_type", pa.string()),
        ("year", pa.int64()),
        ("quarter", pa.string()),
    ])

    for file in FILES:
        parquet_file = f"{path_to_local_home}/indego-trips-{file['year']}-{file['quarter']}.parquet"
        if os.path.exists(parquet_file):
            table = pq.read_table(parquet_file)

            # Convert bike_id to string if necessary
            if table.schema.field("bike_id").type != pa.string():
                table = table.set_column(
                    table.schema.get_field_index("bike_id"), "bike_id", table.column("bike_id").cast(pa.string())
                )
            
            tables.append(table)

    if tables:
        merged_table = pa.concat_tables(tables).combine_chunks()
        merged_table = merged_table.cast(expected_schema)  # Ensure final schema consistency
        pq.write_table(merged_table, f"{path_to_local_home}/indego_all_trips.parquet")
        upload_to_gcs(BUCKET, "raw/indego_all_trips.parquet", f"{path_to_local_home}/indego_all_trips.parquet")
        logging.info("Merged all trip files into a single Parquet file and uploaded to GCS.")
    else:
        logging.error("No Parquet files found to merge.")


def process_stations_data():
    """Download, process, and upload stations data to GCS."""
    stations_url = "https://www.rideindego.com/wp-content/uploads/2025/01/indego-stations-2025-01-01.csv"
    stations_file = f"{path_to_local_home}/indego-stations-2025-01-01.csv"
    parquet_file = stations_file.replace('.csv', '.parquet')

    # Download the stations CSV file
    os.system(f"curl -sSL -o {stations_file} {stations_url}")

    # Read the CSV file into a PyArrow table
    table = pv.read_csv(stations_file)

    # Ensure all column names are valid (replace empty or invalid names)
    valid_column_names = [col if col.strip() else f"Unnamed_{i}" for i, col in enumerate(table.column_names)]
    table = table.rename_columns(valid_column_names)

    # Remove columns with names starting with 'Unnamed_'
    columns_to_keep = [col for col in table.column_names if not col.startswith("Unnamed_")]
    table = table.select(columns_to_keep)

    # Write the table to a Parquet file
    pq.write_table(table, parquet_file)

    # Upload to GCS
    upload_to_gcs(BUCKET, "raw/indego_stations.parquet", parquet_file)
    logging.info(f"Uploaded {parquet_file} to GCS.")


with DAG(
    dag_id="data_ingestion_gcs_dag",
    schedule_interval="@daily",
    default_args=default_args,
    catchup=False,
    max_active_runs=1,
    tags=['dtc-de'],
) as dag:

    merge_task = PythonOperator(
        task_id="merge_all_trips",
        python_callable=merge_all_trips,
    )
    
    create_external_table = BigQueryCreateExternalTableOperator(
        task_id="create_external_bq_table",
        table_resource={
            "tableReference": {
                "projectId": PROJECT_ID,
                "datasetId": BIGQUERY_DATASET,
                "tableId": "indego_trips_all",
            },
            "externalDataConfiguration": {
                "sourceUris": [f"gs://{BUCKET}/raw/indego_all_trips.parquet"],
                "sourceFormat": "PARQUET",
            },
        },
    )

    process_stations_task = PythonOperator(
        task_id="process_stations_data",
        python_callable=process_stations_data,
    )

    create_stations_external_table = BigQueryCreateExternalTableOperator(
        task_id="create_stations_external_table",
        table_resource={
            "tableReference": {
                "projectId": PROJECT_ID,
                "datasetId": BIGQUERY_DATASET,
                "tableId": "indego_stations",
            },
            "externalDataConfiguration": {
                "sourceUris": [f"gs://{BUCKET}/raw/indego_stations.parquet"],
                "sourceFormat": "PARQUET",
            },
        },
    )
    
    for file in FILES:
        year, quarter, url = file["year"], file["quarter"], file["url"]
        filename = f"indego-trips-{year}-{quarter}.zip"
        parquet_file = filename.replace('.zip', '.parquet')

        download_task = BashOperator(
            task_id=f"download_{year}_{quarter}",
            bash_command=f"curl -sSL -o {path_to_local_home}/{filename} {url} && ls -lh {path_to_local_home}/{filename}"
        )

        format_task = PythonOperator(
            task_id=f"format_parquet_{year}_{quarter}",
            python_callable=format_to_parquet,
            op_kwargs={"zip_file": f"{path_to_local_home}/{filename}", "year": year, "quarter": quarter},
        )

        download_task >> format_task >> merge_task
    
    merge_task >> create_external_table
    process_stations_task >> create_stations_external_table