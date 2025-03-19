{% macro fill_missing_coordinates(table) %}
    WITH start_station_coords AS (
        SELECT start_station,
               MAX(start_lat) AS known_start_lat,
               MAX(start_lon) AS known_start_lon
        FROM {{ table }}
        WHERE start_lat IS NOT NULL AND start_lon IS NOT NULL
        GROUP BY start_station
    ),
    end_station_coords AS (
        SELECT end_station,
               MAX(end_lat) AS known_end_lat,
               MAX(end_lon) AS known_end_lon
        FROM {{ table }}
        WHERE end_lat IS NOT NULL AND end_lon IS NOT NULL
        GROUP BY end_station
    )
    SELECT 
        ssc.start_station,
        ssc.known_start_lat,
        ssc.known_start_lon,
        esc.end_station,
        esc.known_end_lat,
        esc.known_end_lon
    FROM start_station_coords ssc
    FULL OUTER JOIN end_station_coords esc ON ssc.start_station = esc.end_station
{% endmacro %}