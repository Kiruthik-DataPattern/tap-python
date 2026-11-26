-- Day 7 task 9: size evidence for the ETL vs ELT decision.
-- Run Day 16 build_tables.sql and fact_reviews.sql first.
-- table_rows is approximate for InnoDB; the COUNT queries below are exact.

SELECT table_name,
       table_rows,
       ROUND(data_length / 1024 / 1024, 2) AS data_mb,
       ROUND(index_length / 1024 / 1024, 2) AS index_mb
FROM information_schema.tables
WHERE table_schema = DATABASE()
  AND table_name IN (
      'stg_orders', 'stg_order_items', 'stg_customers', 'stg_products',
      'stg_sellers', 'stg_order_payments', 'stg_order_reviews',
      'dim_customer', 'dim_product', 'dim_seller', 'dim_payment_type',
      'dim_date', 'fact_sales', 'fact_reviews'
  )
ORDER BY data_length DESC;

SELECT (SELECT COUNT(*) FROM stg_orders) AS source_orders,
       (SELECT COUNT(*) FROM stg_order_items) AS source_items,
       (SELECT COUNT(*) FROM fact_sales) AS fact_items,
       (SELECT COUNT(*) FROM stg_order_reviews) AS source_reviews,
       (SELECT COUNT(*) FROM fact_reviews) AS fact_reviews;
