{{ config(
    materialized='table'
) }}

SELECT 
    EXTRACT(HOUR FROM start_dt) AS hour_numeric,
    FORMAT_DATETIME('%I %p', start_dt) AS hour_label,
    FORMAT_DATETIME('%A', start_dt) AS day_of_week,
    CASE
        WHEN EXTRACT(DAYOFWEEK FROM start_dt) IN (1, 7) THEN 'Weekend'
        ELSE 'Weekday'
    END AS day_type,
    FORMAT_DATETIME('%B', start_dt) AS month_name,
    EXTRACT(YEAR FROM start_dt) AS year,
    ROUND(COUNT(*) / COUNT(DISTINCT DATE(start_dt)), 2) AS avg_ridership_per_hour
FROM {{ ref('fact_trips') }}
GROUP BY hour_numeric, hour_label, day_of_week, day_type, month_name, year
ORDER BY year, month_name, day_of_week, hour_numeric
