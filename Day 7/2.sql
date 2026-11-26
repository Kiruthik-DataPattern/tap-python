-- Day 7 task 2: data needed to confirm the fact_sales source-to-target mapping.
-- Run Day 16 build_tables.sql first.

-- Sample of the joined source rows that become one fact row.
SELECT i.order_id, i.order_item_id, i.price, i.freight_value,
       o.customer_id, i.product_id, i.seller_id,
       o.order_purchase_timestamp, o.order_status
FROM stg_order_items i
JOIN stg_orders o ON o.order_id = i.order_id
ORDER BY o.order_purchase_timestamp
LIMIT 10;

-- Check that every source item can find its dimension row.
SELECT COUNT(*) AS source_items,
       SUM(c.customer_key IS NULL) AS missing_customer,
       SUM(p.product_key IS NULL) AS missing_product,
       SUM(s.seller_key IS NULL) AS missing_seller,
       SUM(pt.payment_type_key IS NULL) AS missing_payment_type
FROM stg_order_items i
JOIN stg_orders o ON o.order_id = i.order_id
LEFT JOIN dim_customer c ON c.customer_id = o.customer_id
LEFT JOIN dim_product p ON p.product_id = i.product_id
LEFT JOIN dim_seller s ON s.seller_id = i.seller_id
LEFT JOIN (
    SELECT order_id, payment_type FROM (
        SELECT order_id, payment_type,
               ROW_NUMBER() OVER (PARTITION BY order_id ORDER BY payment_sequential) AS rn
        FROM stg_order_payments
    ) ranked WHERE rn = 1
) first_pay ON first_pay.order_id = i.order_id
LEFT JOIN dim_payment_type pt ON pt.payment_type = first_pay.payment_type;

-- Derived columns should add up.
SELECT COUNT(*) AS items_where_value_differs
FROM fact_sales
WHERE ROUND(price + freight_value, 2) <> ROUND(price, 2) + ROUND(freight_value, 2);
