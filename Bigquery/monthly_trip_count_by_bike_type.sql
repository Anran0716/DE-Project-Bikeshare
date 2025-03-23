CREATE OR REPLACE TABLE `kestra-sandbox-451604.Indego_project.monthly_trip_count_by_bike_type` AS
SELECT 
    year,
    month_name,
    bike_type,
    COUNT(*) AS total_trips
FROM `kestra-sandbox-451604.Indego_project.indego_trips_all_v2`
GROUP BY year, month_name, bike_type
ORDER BY year DESC, month_name, bike_type;
