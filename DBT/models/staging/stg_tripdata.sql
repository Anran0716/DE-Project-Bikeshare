{{ config(
    materialized='table'
) }}

-- Step 1: Remove Duplicates
WITH filtered AS (
    {{ remove_duplicates('database.Indego_project.indego_trips_all') }}
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

        -- Use the format_duration_time macro
        {{ format_duration_time('f.duration', 'f.start_time') }},

    FROM filtered f
    LEFT JOIN station_coordinate sc_start
        ON f.start_station = sc_start.station_id
    LEFT JOIN station_coordinate sc_end
        ON f.end_station = sc_end.station_id


