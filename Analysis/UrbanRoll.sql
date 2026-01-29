SELECT * FROM `my-project-485806.rental_e_bike.rides` LIMIT 1000;

SELECT * FROM `my-project-485806.rental_e_bike.stations` LIMIT 1000;

SELECT * FROM `my-project-485806.rental_e_bike.users` LIMIT 1000;

-- Find the total rows per table:
select 'Rows in users table' as Table_name,count(*) as counts from `my-project-485806.rental_e_bike.users`
UNION ALL
select 'Rows in Rides table' as Table_name, count(*) as counts from `my-project-485806.rental_e_bike.rides`
UNION ALL
select 'Rows in stations table' as Table_name,count(*) as counts from `my-project-485806.rental_e_bike.stations`
;

-- Missing data:
SELECT
  COUNTIF(ride_id IS NULL) AS null_ride_ids,
  COUNTIF(user_id IS NULL) AS null_user_ids,
  COUNTIF(start_time IS NULL) AS null_start_time,
  COUNTIF(end_time IS NULL) AS null_end_time
FROM `my-project-485806.rental_e_bike.rides` ;

-- Summary statistics for the rides table:

SELECT 
  MIN(distance_km) AS min_dist,
  MAX(distance_km) AS max_dist,
  ROUND(AVG(distance_km),2) AS avg_dist,
  MIN(TIMESTAMP_DIFF(end_time, start_time, MINUTE)) AS min_duration_mins,
  MAX(TIMESTAMP_DIFF(end_time, start_time, MINUTE)) AS max_duration_mins,
  ROUND(AVG(TIMESTAMP_DIFF(end_time, start_time, MINUTE)),2) AS avg_duration_mins
FROM `my-project-485806.rental_e_bike.rides` ;

-- Data quality(false start for the rides:)

SELECT
  COUNTIF(TIMESTAMP_DIFF(end_time, start_time, MINUTE)< 2) AS short_duration_trips,
  COUNTIF(distance_km = 0) AS zero_distance_trips
FROM `my-project-485806.rental_e_bike.rides` ;

-- Different membership:
SELECT 
  u.membership_level,
  COUNT(r.ride_id) AS total_rides,
  ROUND(AVG(r.distance_km),2) AS avg_distance_km,
  ROUND(AVG(TIMESTAMP_DIFF(r.end_time, r.start_time, MINUTE)),2) AS avg_duration_mins
FROM `my-project-485806.rental_e_bike.rides` AS r
JOIN `my-project-485806.rental_e_bike.users` AS u
  ON r.user_id = u.user_id
GROUP BY u.membership_level
ORDER BY total_rides DESC;

-- Peak rides(in hours):

SELECT 
  EXTRACT(HOUR FROM start_time)  AS hour_of_day,
  COUNT(*) AS ride_count
FROM `my-project-485806.rental_e_bike.rides`
GROUP BY EXTRACT(HOUR FROM start_time)
ORDER BY ride_count DESC;

-- Popular Stations:
SELECT
  s.station_name, 
  COUNT(r.ride_id) AS total_start_ride
FROM `my-project-485806.rental_e_bike.rides` AS r
JOIN `my-project-485806.rental_e_bike.stations` AS s
ON r.start_station_id = s.station_id
GROUP BY s.station_name
ORDER BY total_start_ride DESC
LIMIT 10;

-- Ride in-depth analysis:

SELECT 
CASE
  WHEN TIMESTAMP_DIFF(end_time, start_time, MINUTE) <= 10 THEN 'Short (<10m)'
  WHEN TIMESTAMP_DIFF(end_time, start_time, MINUTE) BETWEEN 11 AND 30 THEN 'Medium(11 - 30m)'
  ELSE 'Long (>30m)'
END AS ride_category,
COUNT(*) AS ride_counts
FROM `my-project-485806.rental_e_bike.rides`
GROUP BY ride_category
ORDER BY ride_counts;

-- Net flow for each stations:

WITH departures AS(
SELECT start_station_id, count(*) as total_departures
FROM `my-project-485806.rental_e_bike.rides`
GROUP BY start_station_id
),
arrivals as (
SELECT end_station_id, count(*) as total_arrivals
FROM `my-project-485806.rental_e_bike.rides`
GROUP BY end_station_id
)

SELECT s.station_name, d.total_departures, a.total_arrivals,
(a.total_arrivals - d.total_departures) as net_flow
FROM `my-project-485806.rental_e_bike.stations` AS s
JOIN departures as d
ON s.station_id = d.start_station_id
JOIN arrivals as a
ON s.station_id = a.end_station_id
ORDER BY net_flow DESC;


-- User retention:

WITH monthly_signups AS (
  SELECT
    DATE_TRUNC(created_at, MONTH) as signup_month,
    COUNT(user_id) as new_user_count
  FROM `my-project-485806.rental_e_bike.users`
  GROUP BY DATE_TRUNC(created_at, MONTH)
)
SELECT signup_month, 
  new_user_count,
  LAG(new_user_count) OVER(ORDER BY signup_month) AS prev_month_count,
  (new_user_count - LAG(new_user_count) OVER(ORDER BY signup_month)) /
  nullif(LAG(new_user_count) OVER(ORDER BY signup_month),0) *100 as pct_growth
FROM monthly_signups
ORDER BY signup_month;


-- 

