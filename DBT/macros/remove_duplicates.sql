{% macro remove_duplicates(table) %}
    WITH deduplicated AS (
        SELECT 
            *, 
            ROW_NUMBER() OVER (
                PARTITION BY trip_id, start_time, end_time, start_station, end_station, bike_id, passholder_type 
                ORDER BY trip_id
            ) AS rn 
        FROM {{ table }}
        WHERE trip_id IS NOT NULL
          AND start_time IS NOT NULL
          AND end_time IS NOT NULL
          AND start_station IS NOT NULL
          AND end_station IS NOT NULL
          AND bike_id IS NOT NULL
          AND duration IS NOT NULL
    )
    SELECT * FROM deduplicated WHERE rn = 1
{% endmacro %}