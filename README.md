# DE-Project-Bikeshare

## Problem Statement

Philadelphia’s bikeshare system, [Indego](https://www.rideindego.com/), has provided communities across the city access to public bikes for over eight years. The goal of this project is to develop a data pipeline and dashboard, which provides periodic analysis of bikeshare usage patterns and travel demand trends.

<img src="Figures/indego.jpg" alt="Indego" height="300" width="600">

## Datasets

-  [Indego bikeshare trip data 2023 - 2024](https://www.rideindego.com/about/data/)

## Workflow

<img src="Figures/workflow.jpg" alt="wf" height="400" width="800">

The ETL pipeline is designed to Extract data from various sources, Transform it using DBT, and Load it into BigQuery for analysis. The process involves the following steps:
- **Extraction:** Docker containerized Airflow orchestrates data extraction from CSV files.
- **Loading:** Extracted data is loaded into BigQuery using Airflow DAGs.
- **Transformation:** DBT performs data cleaning, normalization, and aggregation directly in BigQuery.
- **Visualization:** Transformed data is visualized using Power BI, providing actionable insights into bike share usage.


### Tools & Technology

- **Cloud Provider:** Google Cloud Platform (GCP)
- **Orchestration:** Apache Airflow (Containerized with Docker)
- **Data Processing:** DBT for transformations
- **Storage & Querying:** GCS, BigQuery
- **Visualization:** Power BI

### Dashboard & Visualization

## General Guidance

**Step 1: Setup**

- Set up GCP environment, Docker, and configure necessary IAM roles.

**Step 2: Data Ingestion & Loading**

- Use Docker to containerize the pipeline. 
- Build Airflow DAGs for workflow automation.
- Load the raw data in Google Bigquery. 

**Step 3: Data Transformation**

- Implement data partitioning and indexing in BigQuery.
- Optimize data transformations using DBT.

**Step 4: Data Visualization**

- Build Power BI dashboards for analytics and insights.