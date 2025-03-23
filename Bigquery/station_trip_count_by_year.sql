CREATE OR REPLACE TABLE `kestra-sandbox-451604.Indego_project.station_trip_count_by_year` AS
WITH station_trips AS (
    SELECT 
        year,
        start_station AS station_id,
        start_station_name AS station_name,
        start_lat AS lat,
        start_lon AS lon,
        'origin' AS station_type,
        COUNT(*) AS trip_count
    FROM `kestra-sandbox-451604.Indego_project.indego_trips_all_v2`
    WHERE start_station IS NOT NULL
    GROUP BY year, station_id, station_name, lat, lon
    
    UNION ALL
    
    SELECT 
        year,
        end_station AS station_id,
        end_station_name AS station_name,
        end_lat AS lat,
        end_lon AS lon,
        'destination' AS station_type,
        COUNT(*) AS trip_count
    FROM `kestra-sandbox-451604.Indego_project.indego_trips_all_v2`
    WHERE end_station IS NOT NULL
    GROUP BY year, station_id, station_name, lat, lon
)
SELECT *
FROM station_trips
ORDER BY year DESC, trip_count DESC;
