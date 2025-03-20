{{ config(
    materialized='table'
) }}

SELECT 
    year,
    CONCAT(ROUND(COUNT(*) / 1000000.0, 2), ' M') AS total_trips,
    CONCAT(ROUND(SUM(duration) / 1000000.0, 2), ' M hr') AS total_duration,
    ROUND(AVG(duration), 2) AS avg_trip_duration,
    
    -- Bike Type Percentages
    SAFE_CAST(COUNTIF(bike_type = 'electric') * 100 / COUNT(*) AS INT) AS electric_bike_pct,
    SAFE_CAST(COUNTIF(bike_type = 'standard') * 100 / COUNT(*) AS INT) AS classic_bike_pct,

    -- Passholder Type Percentages
    SAFE_CAST(COUNTIF(passholder_type = 'Indego365') * 100 / COUNT(*) AS INT) AS monthly_pass_pct,
    SAFE_CAST(COUNTIF(passholder_type = 'Indego30') * 100 / COUNT(*) AS INT) AS annual_pass_pct,
    SAFE_CAST(COUNTIF(passholder_type = 'Day Pass') * 100 / COUNT(*) AS INT) AS walkup_pct

FROM {{ ref('fact_trips') }}
GROUP BY year
ORDER BY year DESC
