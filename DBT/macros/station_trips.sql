{% macro station_trips(trip_table) %}
(
    SELECT 
        year,
        start_station AS station_id,
        start_station_name AS station_name,
        start_lat AS lat,
        start_lon AS lon,
        'origin' AS station_type,
        COUNT(*) AS trip_count
    FROM {{ ref(trip_table) }}
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
    FROM {{ ref(trip_table) }}
    WHERE end_station IS NOT NULL
    GROUP BY year, station_id, station_name, lat, lon
)
{% endmacro %}
