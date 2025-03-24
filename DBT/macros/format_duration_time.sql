{% macro format_duration_time(duration_column, start_time_column) %}
    -- Step 2: Add Duration with Unit
    CASE 
        WHEN {{ duration_column }} < 60 THEN CONCAT(CAST({{ duration_column }} AS STRING), ' min')
        ELSE CONCAT(CAST(ROUND({{ duration_column }} / 60, 2) AS STRING), ' hr')
    END AS duration_with_unit,

    -- Step 3: Add Day of Week, Weekday/Weekend, Month, Hour Labels
    FORMAT_TIMESTAMP('%A', PARSE_TIMESTAMP('%m/%d/%Y %H:%M', {{ start_time_column }})) AS day_of_week,

    CASE 
        WHEN FORMAT_TIMESTAMP('%A', PARSE_TIMESTAMP('%m/%d/%Y %H:%M', {{ start_time_column }})) IN ('Saturday', 'Sunday') 
        THEN 'Weekend' 
        ELSE 'Weekday' 
    END AS day_type,

    FORMAT_TIMESTAMP('%B', PARSE_TIMESTAMP('%m/%d/%Y %H:%M', {{ start_time_column }})) AS month_name,

    FORMAT_TIMESTAMP('%I %p', PARSE_TIMESTAMP('%m/%d/%Y %H:%M', {{ start_time_column }})) AS hour_label
{% endmacro %}

