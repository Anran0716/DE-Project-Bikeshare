CREATE OR REPLACE TABLE `database.Indego_project.monthly_trip_count_by_bike_type` AS
SELECT 
    year,
    month_name,
    bike_type,
    COUNT(*) AS total_trips
FROM `database.Indego_project.indego_trips_staging`
GROUP BY year, month_name, bike_type
ORDER BY year DESC, month_name, bike_type;
