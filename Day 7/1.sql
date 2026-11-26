-- Day 7 task 1: source inventory.
-- Run Day 16 build_tables.sql and fact_reviews.sql first.
-- The row counts and business keys below are what you use to fill the inventory.

SELECT 'olist_orders_dataset.csv' AS file_name, COUNT(*) AS rows_in_table,
       'order_id' AS business_key
FROM stg_orders
UNION ALL
SELECT 'olist_customers_dataset.csv', COUNT(*), 'customer_id'
FROM stg_customers
UNION ALL
SELECT 'olist_order_items_dataset.csv', COUNT(*), 'order_id + order_item_id'
FROM stg_order_items
UNION ALL
SELECT 'olist_order_payments_dataset.csv', COUNT(*), 'order_id + payment_sequential'
FROM stg_order_payments
UNION ALL
SELECT 'olist_order_reviews_dataset.csv', COUNT(*), 'review_id'
FROM stg_order_reviews
UNION ALL
SELECT 'olist_products_dataset.csv', COUNT(*), 'product_id'
FROM stg_products
UNION ALL
SELECT 'olist_sellers_dataset.csv', COUNT(*), 'seller_id'
FROM stg_sellers
UNION ALL
SELECT 'product_category_name_translation.csv', COUNT(*), 'product_category_name'
FROM stg_category_translation;

-- The semicolon orders file is the same data as stg_orders, so it is not counted twice.
-- If you also loaded geolocation, run this separately:
-- SELECT COUNT(*) AS rows_in_table, 'zip_code_prefix + lat + lng' AS business_key
-- FROM stg_geolocation;

-- This shows how often orders arrive, which supports the "daily append" assumption.
SELECT MIN(order_purchase_timestamp) AS first_order,
       MAX(order_purchase_timestamp) AS last_order,
       COUNT(*) AS orders,
       COUNT(DISTINCT DATE(order_purchase_timestamp)) AS active_days
FROM stg_orders;

SELECT DATE(order_purchase_timestamp) AS order_date, COUNT(*) AS orders
FROM stg_orders
GROUP BY DATE(order_purchase_timestamp)
ORDER BY order_date DESC
LIMIT 10;
