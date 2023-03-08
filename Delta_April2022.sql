/* A look at Delta's Flight Operations in the month 
of April of 2022. This is basically an overview, and
using SQL to look through the data provided (listed below).*/

/* Joining three tables:
	flights - DOT Flight Data - April 2022 (https://www.transtats.bts.gov/Fields.asp?gnoyr_VQ=FGJ)
	owner - FAA aircraft registration
	type - FAA aircraft type*/

SELECT *
FROM flights f
LEFT JOIN owner o
	ON f.tail_num = o.nnumber
LEFT JOIN type t
	ON t.code = o.model

/*Number of flight per day by Delta as the market carrier, as
well as a summary of a number of variables.*/

SELECT  
CAST(f.fl_date AS date) AS "Flight Date", 
COUNT(mkt_carrier_fl_num) AS "Total Segments",
COUNT(DISTINCT f.tail_num) AS "# Planes Used",
SUM(f.distance) AS "Miles Flown",
ROUND(SUM((f.air_time)/60),2) AS "Hours Flown",
SUM(CASE
	WHEN f.dep_delay >=30 THEN 1
	ELSE 0 END) AS "Delayed 30+ Minutes",
SUM(f.cancelled) AS "Cancelled Flights",
SUM(f.diverted) AS "Diverted Flights"
FROM flights f
WHERE f.mkt_carrier = 'DL'
GROUP BY f.fl_date
ORDER BY 1 ASC


/* All Delta aircraft by total miles/minutes (rounded up) flown in April 2022.
	Listing tail number and aircraft model*/

SELECT f.tail_num AS "Tail Number",
	t.model AS "Type of Plane", 
	SUM(f.distance) AS "Total Miles for April",
	COUNT(f.tail_num) AS "Total Segments",
	CEILING(SUM(f.air_time)/60) AS "Total Hours in Air",
	SUM(f.cancelled) AS "Cancelled"
FROM flights f
LEFT JOIN owner o
	ON f.tail_num = o.nnumber
LEFT JOIN type t
	ON t.code = o.model
WHERE f.mkt_carrier = 'DL'
GROUP BY f.tail_num, t.model
ORDER BY 3 DESC


/* Flight data by departure airport.
NOTE: Added aiport table to display airport names for
easier reference.
*/

SELECT f.origin AS "IATA Code",
	a.airport_name as "Aiport Name",
	COUNT (f.origin) AS "Total Departures",
	COUNT (CASE
		WHEN f.dep_delay >=15 THEN f.dep_delay
		ELSE NULL END) AS "Delayed Flights",
	SUM (f.cancelled) AS "Cancelled Flights",
	CEILING(AVG (f.taxi_out)) AS "Taxing Time (Minutes)",
	CEILING(AVG (CASE
		WHEN f.dep_delay >=15 THEN f.dep_delay
		ELSE NULL END)) AS "Average Delay Time (over 15m)"
FROM flights f
LEFT JOIN airport a
	ON a.locid = f.origin
WHERE mkt_carrier = 'DL'
GROUP BY f.origin, a.airport_name
ORDER BY 3 DESC


/* Breakdown of flight departure times by time of the day
and airport*/
SELECT origin AS "Airport",
	COUNT(CASE
		WHEN f.dep_time < 0600 THEN 1
		ELSE NULL END) AS "Before 6 AM",
	COUNT(CASE
		WHEN f.dep_time >= 0600 AND f.dep_time <=1199 THEN 1
		ELSE NULL END) AS "6 AM - 11:59 AM",
	COUNT(CASE
		WHEN f.dep_time >= 1200 AND f.dep_time <=1699 THEN 1
		ELSE NULL END) AS "12:00 PM - 4:59 PM",
	COUNT(CASE
		WHEN f.dep_time >=1700 AND f.dep_time <=2099 THEN 1
		ELSE NULL END) AS "5:00 PM to 8:59 PM",
	COUNT(CASE
		WHEN f.dep_time >2100 THEN 1
		ELSE NULL END) AS "After 9:00 PM",
	COUNT(f.origin) AS "Total Departures"
FROM flights f
WHERE mkt_carrier = 'DL'
GROUP BY origin
ORDER BY 1

/*Reasons for Cancellations by Aircraft. Ordered by the
aircraft with most cancellations.*/
SELECT o.nnumber AS "Aircraft",
	t.model "Model",
	SUM(f.cancelled) AS "Total Cancellations",
	COUNT(CASE
		WHEN f.cancellation_code = 'A' THEN 1
		ELSE NULL END) AS "Carrier",
	COUNT(CASE
		WHEN f.cancellation_code = 'B' THEN 1
		ELSE NULL END) AS "Extreme Weather",
	COUNT(CASE
		WHEN f.cancellation_code = 'C' THEN 1
		ELSE NULL END) AS "National Air System",
	COUNT(CASE
		WHEN f.cancellation_code = 'D' THEN 1
		ELSE NULL END) AS "Security",
	COUNT(CASE
		WHEN f.cancellation_code = '-' THEN 1
		ELSE NULL END) AS "Unknown"
FROM flights f
LEFT JOIN owner o
	ON f.tail_num = o.nnumber
LEFT JOIN type t
	ON t.code = o.model
WHERE mkt_carrier = 'DL'
GROUP BY o.nnumber, t.model
ORDER BY 3 DESC

/* EXTRA DATA REGARDING DELTA IN APRIL 2022*/

/*Determine average age by plane type
for each of the aircraft flown by Delta in April 2022.
Also, the oldest and newest aircraft for each
aircraft model*/

SELECT t.model AS "Aircraft Type", 
	COUNT (DISTINCT f.tail_num) AS "Number of Planes",
	2022-AVG(o.yearmade) AS "Average Age by Years",
	MAX(o.yearmade) AS "Newest",
	MIN(o.yearmade) AS "Oldest"
FROM flights f
LEFT JOIN owner o
	ON f.tail_num = o.nnumber
LEFT JOIN type t
	ON t.code = o.model
WHERE f.mkt_carrier = 'DL'
GROUP BY t.model
ORDER BY 2 DESC
