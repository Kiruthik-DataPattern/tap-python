-- Day 7 task 3: data needed to confirm the dim_customer mapping.
-- Run Day 16 build_tables.sql first.

-- How many source rows and how many distinct keys.
SELECT COUNT(*) AS source_rows,
       COUNT(DISTINCT customer_id) AS distinct_customer_id,
       COUNT(DISTINCT customer_unique_id) AS distinct_customer_unique_id
FROM stg_customers;

-- customer_id should be unique in the source; any row here is a problem.
SELECT customer_id, COUNT(*) AS rows_per_id
FROM stg_customers
GROUP BY customer_id
HAVING COUNT(*) > 1
ORDER BY rows_per_id DESC
LIMIT 10;

-- Null or blank location values.
SELECT SUM(customer_zip_code_prefix IS NULL OR customer_zip_code_prefix = '') AS missing_zip,
       SUM(customer_city IS NULL OR customer_city = '') AS missing_city,
       SUM(customer_state IS NULL OR customer_state = '') AS missing_state
FROM stg_customers;

-- Compare source values with the dimension row.
SELECT c.customer_id, c.customer_unique_id, c.customer_zip_code_prefix,
       c.customer_city, c.customer_state,
       d.customer_key, d.city AS dim_city, d.state AS dim_state
FROM stg_customers c
LEFT JOIN dim_customer d ON d.customer_id = c.customer_id
ORDER BY c.customer_id
LIMIT 10;

-- How many source customers never made it into the dimension.
SELECT COUNT(*) AS source_rows,
       SUM(d.customer_key IS NULL) AS missing_in_dim
FROM stg_customers c
LEFT JOIN dim_customer d ON d.customer_id = c.customer_id;
