
-- Step 1: Remove Duplicates, Fill Missing Coordinates, Add Columns, and Join Station Names
CREATE OR REPLACE TABLE database.Indego_project.indego_trips_staging AS
WITH deduplicated AS (
    SELECT 
        *, 
        ROW_NUMBER() OVER (
            PARTITION BY trip_id, start_time, end_time, start_station, end_station, bike_id, passholder_type 
            ORDER BY trip_id
        ) AS rn
    FROM database.Indego_project.indego_trips_all
    WHERE trip_id IS NOT NULL 
      AND start_time IS NOT NULL 
      AND end_time IS NOT NULL
      AND start_station IS NOT NULL 
      AND end_station IS NOT NULL
      AND bike_id IS NOT NULL
      AND duration IS NOT NULL
),
filtered AS (
    SELECT * FROM deduplicated WHERE rn = 1
),
station_coordinate AS (
    SELECT 
        station_id, 
        MAX(lat) AS lat, 
        MAX(lon) AS lon
    FROM (
        SELECT start_station AS station_id, start_lat AS lat, start_lon AS lon FROM filtered
        UNION ALL
        SELECT end_station AS station_id, end_lat AS lat, end_lon AS lon FROM filtered
    )
    WHERE lat IS NOT NULL AND lon IS NOT NULL
    GROUP BY station_id
)

SELECT
    f.* EXCEPT(start_lat, start_lon, end_lat, end_lon),
    COALESCE(sc_start.lat, f.start_lat) AS start_lat,
    COALESCE(sc_start.lon, f.start_lon) AS start_lon,
    COALESCE(sc_end.lat, f.end_lat) AS end_lat,
    COALESCE(sc_end.lon, f.end_lon) AS end_lon,

    -- Step 2: Add Duration with Unit
    CASE 
        WHEN duration < 60 THEN CONCAT(CAST(duration AS STRING), ' min')
        ELSE CONCAT(CAST(ROUND(duration / 60, 2) AS STRING), ' hr')
    END AS duration_with_unit,
    
    -- Step 3: Add Day of Week, Weekday/Weekend, Month, Hour Labels
    FORMAT_TIMESTAMP('%A', PARSE_TIMESTAMP('%m/%d/%Y %H:%M', start_time)) AS day_of_week,
    CASE 
        WHEN FORMAT_TIMESTAMP('%A', PARSE_TIMESTAMP('%m/%d/%Y %H:%M', start_time)) IN ('Saturday', 'Sunday') 
        THEN 'Weekend' 
        ELSE 'Weekday' 
    END AS day_type,
    FORMAT_TIMESTAMP('%B', PARSE_TIMESTAMP('%m/%d/%Y %H:%M', start_time)) AS month_name,
    FORMAT_TIMESTAMP('%I %p', PARSE_TIMESTAMP('%m/%d/%Y %H:%M', start_time)) AS hour_label,

    -- Step 4: Add Station Names
    start_stations.Station_Name AS start_station_name,
    end_stations.Station_Name AS end_station_name

FROM filtered f
LEFT JOIN station_coordinate sc_start
    ON f.start_station = sc_start.station_id
LEFT JOIN station_coordinate sc_end
    ON f.end_station = sc_end.station_id
LEFT JOIN `database.Indego_project.indego_stations` start_stations
    ON f.start_station = start_stations.Station_ID
LEFT JOIN `database.Indego_project.indego_stations` end_stations
    ON f.end_station = end_stations.Station_ID;












