-- Run this in MySQL 8+ before build_tables.sql.
-- The recursive CTE makes one row per day; we then pull out month, quarter, year and weekday.

CREATE TABLE IF NOT EXISTS dim_date (
    date_key INT PRIMARY KEY,
    full_date DATE NOT NULL,
    month TINYINT NOT NULL,
    quarter TINYINT NOT NULL,
    year SMALLINT NOT NULL,
    weekday VARCHAR(10) NOT NULL
);

WITH RECURSIVE days AS (
    SELECT DATE('2016-01-01') AS full_date
    UNION ALL
    SELECT DATE_ADD(full_date, INTERVAL 1 DAY)
    FROM days
    WHERE full_date < '2018-12-31'
)
INSERT INTO dim_date (date_key, full_date, month, quarter, year, weekday)
SELECT
    DATE_FORMAT(full_date, '%Y%m%d'),
    full_date,
    MONTH(full_date),
    QUARTER(full_date),
    YEAR(full_date),
    DAYNAME(full_date)
FROM days;

SELECT COUNT(*) AS days_created FROM dim_date;
