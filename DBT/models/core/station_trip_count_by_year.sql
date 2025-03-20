{{ config(
    materialized='table'
) }}

WITH station_trips AS {{ station_trips('fact_trips') }}

SELECT *
FROM station_trips
ORDER BY year DESC, trip_count DESC