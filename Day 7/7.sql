-- Day 7 task 7: count how many rows break each data quality rule.
-- Run Day 16 build_tables.sql and fact_reviews.sql first.
-- A zero in failed_rows means the rule passes.

SELECT 1 AS rule_no, 'order_id must be 32 hex characters' AS rule_name,
       COUNT(*) AS failed_rows
FROM stg_orders
WHERE order_id NOT REGEXP '^[0-9a-fA-F]{32}$'
UNION ALL
SELECT 2, 'order_item_id must be a positive whole number',
       COUNT(*)
FROM stg_order_items
WHERE order_item_id IS NULL OR order_item_id <= 0
UNION ALL
SELECT 3, 'price must be greater than 0',
       COUNT(*)
FROM stg_order_items
WHERE price IS NULL OR price <= 0
UNION ALL
SELECT 4, 'freight_value must be 0 or more',
       COUNT(*)
FROM stg_order_items
WHERE freight_value IS NULL OR freight_value < 0
UNION ALL
SELECT 5, 'order_purchase_timestamp must parse as a date',
       COUNT(*)
FROM stg_orders
WHERE order_purchase_timestamp IS NULL
   OR order_purchase_timestamp = '0000-00-00 00:00:00'
UNION ALL
SELECT 6, 'order_status must be in the allowed list',
       COUNT(*)
FROM stg_orders
WHERE order_status NOT IN ('delivered','shipped','canceled','unavailable',
                           'invoiced','processing','created','approved')
UNION ALL
SELECT 7, 'customer, product and seller ids must be 32 hex characters',
       (SELECT COUNT(*) FROM stg_customers
        WHERE customer_id NOT REGEXP '^[0-9a-fA-F]{32}$')
     + (SELECT COUNT(*) FROM stg_products
        WHERE product_id NOT REGEXP '^[0-9a-fA-F]{32}$')
     + (SELECT COUNT(*) FROM stg_sellers
        WHERE seller_id NOT REGEXP '^[0-9a-fA-F]{32}$')
UNION ALL
SELECT 8, 'order_id + order_item_id must be unique in fact_sales',
       COUNT(*)
FROM (
    SELECT order_id, order_item_id
    FROM fact_sales
    GROUP BY order_id, order_item_id
    HAVING COUNT(*) > 1
) duplicates
UNION ALL
SELECT 9, 'fact price and freight totals must match the source',
       GREATEST(
           ABS(COALESCE((SELECT SUM(price) FROM fact_sales), 0)
             - COALESCE((SELECT SUM(price) FROM stg_order_items), 0)),
           ABS(COALESCE((SELECT SUM(freight_value) FROM fact_sales), 0)
             - COALESCE((SELECT SUM(freight_value) FROM stg_order_items), 0))
       )
UNION ALL
SELECT 10, 'every fact row must have valid dimension keys',
       COUNT(*)
FROM fact_sales f
LEFT JOIN dim_customer c ON c.customer_key = f.customer_key
LEFT JOIN dim_product p ON p.product_key = f.product_key
LEFT JOIN dim_seller s ON s.seller_key = f.seller_key
LEFT JOIN dim_date d ON d.date_key = f.date_key
WHERE c.customer_key IS NULL
   OR p.product_key IS NULL
   OR s.seller_key IS NULL
   OR d.date_key IS NULL;
