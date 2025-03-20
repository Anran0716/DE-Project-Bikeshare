{% macro fill_station_coordinates(deduplicated_table) %}
(
    SELECT 
        station_id, 
        MAX(lat) AS lat, 
        MAX(lon) AS lon
    FROM (
        SELECT start_station AS station_id, start_lat AS lat, start_lon AS lon FROM {{ deduplicated_table }}
        UNION ALL
        SELECT end_station AS station_id, end_lat AS lat, end_lon AS lon FROM {{ deduplicated_table }}
    )
    WHERE lat IS NOT NULL AND lon IS NOT NULL
    GROUP BY station_id
)
{% endmacro %}
