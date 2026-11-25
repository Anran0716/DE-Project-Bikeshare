{{ config(
    materialized='table'
) }}

SELECT 
    EXTRACT(HOUR FROM start_ts) AS hour_numeric,
    FORMAT_TIMESTAMP('%I %p', start_ts) AS hour_label,
    FORMAT_TIMESTAMP('%A', start_ts) AS day_of_week,
    CASE
        WHEN EXTRACT(DAYOFWEEK FROM start_ts) IN (1, 7) THEN 'Weekend'
        ELSE 'Weekday'
    END AS day_type,
    FORMAT_TIMESTAMP('%B', start_ts) AS month_name,
    EXTRACT(YEAR FROM start_ts) AS year,
    ROUND(COUNT(*) / COUNT(DISTINCT DATE(start_ts)), 2) AS avg_ridership_per_hour
FROM {{ ref('fact_trips') }}
GROUP BY hour_numeric, hour_label, day_of_week, day_type, month_name, year
ORDER BY year, month_name, day_of_week, hour_numeric
