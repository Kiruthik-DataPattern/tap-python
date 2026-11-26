-- Day 7 task 5: data needed to design and test the watermark.
-- Run Day 16 build_tables.sql first.

CREATE TABLE IF NOT EXISTS etl_watermark (
    process_name VARCHAR(50) PRIMARY KEY,
    last_purchase_ts DATETIME
);

-- The timestamp range and the number of active days.
SELECT MIN(order_purchase_timestamp) AS first_order,
       MAX(order_purchase_timestamp) AS last_order,
       COUNT(*) AS orders,
       COUNT(DISTINCT DATE(order_purchase_timestamp)) AS active_days
FROM stg_orders;

-- Orders per year, which is the split used in 6.sql.
SELECT YEAR(order_purchase_timestamp) AS order_year, COUNT(*) AS orders
FROM stg_orders
GROUP BY YEAR(order_purchase_timestamp)
ORDER BY order_year;

-- Current watermark.
SELECT process_name, last_purchase_ts FROM etl_watermark;

-- How many rows the next run would pick up with a 1-day lookback.
SET @last_ts = COALESCE(
    (SELECT last_purchase_ts FROM etl_watermark WHERE process_name = 'sales_load'),
    '2017-01-01 00:00:00'
);

SELECT @last_ts AS watermark_used,
       COUNT(*) AS rows_in_next_slice
FROM stg_orders
WHERE order_purchase_timestamp > DATE_SUB(@last_ts, INTERVAL 1 DAY);
