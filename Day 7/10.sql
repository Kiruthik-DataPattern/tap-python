-- Day 7 task 10: row counts in the order the tables must be loaded.
-- Run Day 16 build_tables.sql and fact_reviews.sql first.
-- If you have not built fact_reviews yet, comment out the last SELECT.

SELECT 1 AS load_step, 'stg_orders' AS table_name, COUNT(*) AS rows_loaded FROM stg_orders
UNION ALL SELECT 2, 'stg_order_items', COUNT(*) FROM stg_order_items
UNION ALL SELECT 3, 'stg_customers', COUNT(*) FROM stg_customers
UNION ALL SELECT 4, 'stg_products', COUNT(*) FROM stg_products
UNION ALL SELECT 5, 'stg_sellers', COUNT(*) FROM stg_sellers
UNION ALL SELECT 6, 'stg_order_payments', COUNT(*) FROM stg_order_payments
UNION ALL SELECT 7, 'stg_order_reviews', COUNT(*) FROM stg_order_reviews
UNION ALL SELECT 8, 'dim_date', COUNT(*) FROM dim_date
UNION ALL SELECT 9, 'dim_customer', COUNT(*) FROM dim_customer
UNION ALL SELECT 10, 'dim_product', COUNT(*) FROM dim_product
UNION ALL SELECT 11, 'dim_seller', COUNT(*) FROM dim_seller
UNION ALL SELECT 12, 'dim_payment_type', COUNT(*) FROM dim_payment_type
UNION ALL SELECT 13, 'fact_sales', COUNT(*) FROM fact_sales
UNION ALL SELECT 14, 'fact_reviews', COUNT(*) FROM fact_reviews
ORDER BY load_step;

-- Dependency check: every fact row must find its dimensions.
SELECT COUNT(*) AS facts_missing_dimension
FROM fact_sales f
LEFT JOIN dim_customer c ON c.customer_key = f.customer_key
LEFT JOIN dim_product p ON p.product_key = f.product_key
LEFT JOIN dim_seller s ON s.seller_key = f.seller_key
LEFT JOIN dim_date d ON d.date_key = f.date_key
WHERE c.customer_key IS NULL
   OR p.product_key IS NULL
   OR s.seller_key IS NULL
   OR d.date_key IS NULL;
