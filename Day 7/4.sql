-- Day 7 task 4: data needed to choose the SCD type for each dim_customer attribute.
-- If these attributes never change for a customer, Type 1 is enough.
-- If they do change, Type 2 keeps the history correct.

SELECT COUNT(*) AS unique_customers,
       SUM(city_count > 1) AS with_multiple_cities,
       SUM(state_count > 1) AS with_multiple_states,
       SUM(zip_count > 1) AS with_multiple_zips
FROM (
    SELECT customer_unique_id,
           COUNT(DISTINCT customer_city) AS city_count,
           COUNT(DISTINCT customer_state) AS state_count,
           COUNT(DISTINCT customer_zip_code_prefix) AS zip_count
    FROM stg_customers
    GROUP BY customer_unique_id
) per_customer;

-- The customers that actually changed location.
SELECT customer_unique_id,
       COUNT(DISTINCT customer_city) AS cities,
       COUNT(DISTINCT customer_state) AS states,
       COUNT(DISTINCT customer_zip_code_prefix) AS zips
FROM stg_customers
GROUP BY customer_unique_id
HAVING cities > 1 OR states > 1 OR zips > 1
ORDER BY cities DESC, states DESC, zips DESC
LIMIT 20;
