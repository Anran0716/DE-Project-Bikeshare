{{ config(
    materialized='table'
) }}

SELECT 
    year,
    FORMAT_TIMESTAMP('%B', start_ts) AS month_name,
    bike_type,
    COUNT(*) AS total_trips
FROM {{ ref('fact_trips') }}
GROUP BY year, month_name, bike_type
ORDER BY year DESC, month_name, bike_type
