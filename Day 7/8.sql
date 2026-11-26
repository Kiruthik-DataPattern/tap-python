-- Day 7 task 8: find facts and dimensions that need late-arrival handling.
-- Run Day 16 build_tables.sql first.

-- Facts that already point at the unknown member.
SELECT COUNT(*) AS facts_with_unknown_customer FROM fact_sales WHERE customer_key = -1;
SELECT COUNT(*) AS facts_with_unknown_product FROM fact_sales WHERE product_key = -1;
SELECT COUNT(*) AS facts_with_unknown_seller FROM fact_sales WHERE seller_key = -1;

-- Facts that cannot find their dimension row at all.
SELECT COUNT(*) AS facts_missing_any_dimension
FROM fact_sales f
LEFT JOIN dim_customer c ON c.customer_key = f.customer_key
LEFT JOIN dim_product p ON p.product_key = f.product_key
LEFT JOIN dim_seller s ON s.seller_key = f.seller_key
LEFT JOIN dim_date d ON d.date_key = f.date_key
WHERE c.customer_key IS NULL
   OR p.product_key IS NULL
   OR s.seller_key IS NULL
   OR d.date_key IS NULL;

-- Natural keys that appear in the source but have no dimension row yet.
-- These are the late-arriving dimension rows to insert first.
SELECT 'customer' AS dimension_name, o.customer_id AS natural_key,
       COUNT(*) AS fact_rows
FROM stg_orders o
LEFT JOIN dim_customer c ON c.customer_id = o.customer_id
WHERE c.customer_key IS NULL
GROUP BY o.customer_id
UNION ALL
SELECT 'product', i.product_id, COUNT(*)
FROM stg_order_items i
LEFT JOIN dim_product p ON p.product_id = i.product_id
WHERE p.product_key IS NULL
GROUP BY i.product_id
UNION ALL
SELECT 'seller', i.seller_id, COUNT(*)
FROM stg_order_items i
LEFT JOIN dim_seller s ON s.seller_id = i.seller_id
WHERE s.seller_key IS NULL
GROUP BY i.seller_id
ORDER BY fact_rows DESC
LIMIT 20;
