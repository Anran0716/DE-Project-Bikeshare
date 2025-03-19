{{
    config(
        materialized='view'
    )
}}

WITH filtered AS (
    {{ remove_duplicates(source('staging', 'indego_trips_all')) }}
),
coords AS (
    {{ fill_missing_coordinates(source('staging', 'indego_trips_all')) }}
)
SELECT 
    t.* EXCEPT(start_lat, start_lon, end_lat, end_lon, rn),
    COALESCE(t.start_lat, c.known_start_lat) AS start_lat, 
    COALESCE(t.start_lon, c.known_start_lon) AS start_lon,
    COALESCE(t.end_lat, c.known_end_lat) AS end_lat, 
    COALESCE(t.end_lon, c.known_end_lon) AS end_lon,
    
    -- Duration with unit
    CASE 
        WHEN duration < 60 THEN CONCAT(CAST(duration AS STRING), ' min')
        ELSE CONCAT(CAST(ROUND(duration / 60, 2) AS STRING), ' hr')
    END AS duration_with_unit,
    
    -- Day of Week, Weekday/Weekend, Month, Hour Labels
    FORMAT_TIMESTAMP('%A', PARSE_TIMESTAMP('%m/%d/%Y %H:%M', start_time)) AS day_of_week,
    CASE 
        WHEN FORMAT_TIMESTAMP('%A', PARSE_TIMESTAMP('%m/%d/%Y %H:%M', start_time)) IN ('Saturday', 'Sunday') 
        THEN 'Weekend' 
        ELSE 'Weekday' 
    END AS day_type,
    FORMAT_TIMESTAMP('%B', PARSE_TIMESTAMP('%m/%d/%Y %H:%M', start_time)) AS month_name,
    FORMAT_TIMESTAMP('%I %p', PARSE_TIMESTAMP('%m/%d/%Y %H:%M', start_time)) AS hour_label
FROM filtered t
LEFT JOIN coords c ON t.start_station = c.start_station AND t.end_station = c.end_station



