{{ config(
    materialized='table'
) }}

-- Step 1: Remove Duplicates
WITH filtered AS (
    {{ remove_duplicates(source('staging', 'indego_trips_all')) }}
),

-- Step 2: Fill Station Coordinates
station_coordinate AS (
    {{ fill_station_coordinates('filtered') }}
)
    SELECT
        f.* EXCEPT(start_lat, start_lon, end_lat, end_lon),
        COALESCE(sc_start.lat, f.start_lat) AS start_lat,
        COALESCE(sc_start.lon, f.start_lon) AS start_lon,
        COALESCE(sc_end.lat, f.end_lat) AS end_lat,
        COALESCE(sc_end.lon, f.end_lon) AS end_lon,

        -- Parse once; schema tests flag invalid values without dropping the rows.
        SAFE.PARSE_DATETIME('%m/%d/%Y %H:%M', f.start_time) AS start_dt,
        SAFE.PARSE_DATETIME('%m/%d/%Y %H:%M', f.end_time) AS end_dt

    FROM filtered f
    LEFT JOIN station_coordinate sc_start
        ON f.start_station = sc_start.station_id
    LEFT JOIN station_coordinate sc_end
        ON f.end_station = sc_end.station_id


