CREATE OR REPLACE TABLE `database.Indego_project.avg_hourly_ridership` AS
SELECT 
    EXTRACT(HOUR FROM SAFE.PARSE_TIMESTAMP('%m/%d/%Y %H:%M', start_time)) AS hour_numeric,
    FORMAT_TIMESTAMP('%I %p', SAFE.PARSE_TIMESTAMP('%m/%d/%Y %H:%M', start_time)) AS hour_label,
    day_of_week,
    day_type,
    month_name,
    EXTRACT(YEAR FROM SAFE.PARSE_TIMESTAMP('%m/%d/%Y %H:%M', start_time)) AS year,
    ROUND(COUNT(*) / COUNT(DISTINCT EXTRACT(DATE FROM SAFE.PARSE_TIMESTAMP('%m/%d/%Y %H:%M', start_time))), 2) AS avg_ridership_per_hour
FROM `database.Indego_project.indego_trips_staging`
GROUP BY hour_numeric, hour_label, day_of_week, day_type, month_name, year
ORDER BY year, month_name, day_of_week, hour_numeric;



