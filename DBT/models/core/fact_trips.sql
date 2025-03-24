{{ config(materialized='table') }}

SELECT 
    t.*, 
    start_stations.Station_Name AS start_station_name, 
    end_stations.Station_Name AS end_station_name
FROM {{ ref('stg_tripdata') }} t 
LEFT JOIN {{ ref('indego-stations') }} AS start_stations
    ON t.start_station = start_stations.Station_ID
LEFT JOIN {{ ref('indego-stations') }} AS end_stations
    ON t.end_station = end_stations.Station_ID

