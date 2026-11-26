-- Day 7 task 6: simulate an incremental load in MySQL.
-- Run Day 16 build_tables.sql and dim_date.sql first.
-- Change C:/path/archive to your own folder.

CREATE TABLE IF NOT EXISTS etl_watermark (
    process_name VARCHAR(50) PRIMARY KEY,
    last_purchase_ts DATETIME
);

DROP TABLE IF EXISTS stg_orders_inc;
CREATE TABLE stg_orders_inc (
    order_id CHAR(32), customer_id CHAR(32), order_status VARCHAR(30),
    order_purchase_timestamp DATETIME, order_approved_at DATETIME,
    order_delivered_carrier_date DATETIME, order_delivered_customer_date DATETIME,
    order_estimated_delivery_date DATETIME
);

DROP TABLE IF EXISTS stg_order_items_inc;
CREATE TABLE stg_order_items_inc (
    order_id CHAR(32), order_item_id INT, product_id CHAR(32), seller_id CHAR(32),
    shipping_limit_date DATETIME, price DECIMAL(10,2), freight_value DECIMAL(10,2)
);

DROP TABLE IF EXISTS stg_order_payments_inc;
CREATE TABLE stg_order_payments_inc (
    order_id CHAR(32), payment_sequential INT, payment_type VARCHAR(30),
    payment_installments INT, payment_value DECIMAL(10,2)
);

LOAD DATA LOCAL INFILE 'C:/path/archive/olist_orders_dataset.csv'
INTO TABLE stg_orders_inc FIELDS TERMINATED BY ',' OPTIONALLY ENCLOSED BY '"'
LINES TERMINATED BY '\n' IGNORE 1 LINES;

LOAD DATA LOCAL INFILE 'C:/path/archive/olist_order_items_dataset.csv'
INTO TABLE stg_order_items_inc FIELDS TERMINATED BY ',' OPTIONALLY ENCLOSED BY '"'
LINES TERMINATED BY '\n' IGNORE 1 LINES;

LOAD DATA LOCAL INFILE 'C:/path/archive/olist_order_payments_dataset.csv'
INTO TABLE stg_order_payments_inc FIELDS TERMINATED BY ',' OPTIONALLY ENCLOSED BY '"'
LINES TERMINATED BY '\n' IGNORE 1 LINES;

-- RUN 1: load year 2017 only.
INSERT INTO fact_sales (
    order_id, order_item_id, customer_key, product_key, seller_key,
    date_key, payment_type_key, price, freight_value, item_count, order_status
)
SELECT
    i.order_id, i.order_item_id, c.customer_key, p.product_key, s.seller_key,
    DATE_FORMAT(o.order_purchase_timestamp, '%Y%m%d'),
    pt.payment_type_key, i.price, i.freight_value, 1, o.order_status
FROM stg_order_items_inc i
JOIN stg_orders_inc o ON o.order_id = i.order_id
JOIN dim_customer c ON c.customer_id = o.customer_id
JOIN dim_product p ON p.product_id = i.product_id
JOIN dim_seller s ON s.seller_id = i.seller_id
LEFT JOIN (
    SELECT order_id, payment_type FROM (
        SELECT order_id, payment_type,
               ROW_NUMBER() OVER (PARTITION BY order_id ORDER BY payment_sequential) AS rn
        FROM stg_order_payments_inc
    ) ranked WHERE rn = 1
) first_pay ON first_pay.order_id = i.order_id
LEFT JOIN dim_payment_type pt ON pt.payment_type = first_pay.payment_type
WHERE o.order_purchase_timestamp >= '2017-01-01'
  AND o.order_purchase_timestamp <  '2018-01-01'
  AND NOT EXISTS (
      SELECT 1 FROM fact_sales f
      WHERE f.order_id = i.order_id AND f.order_item_id = i.order_item_id
  );

INSERT INTO etl_watermark (process_name, last_purchase_ts)
VALUES ('sales_load', '2017-12-31 23:59:59')
ON DUPLICATE KEY UPDATE last_purchase_ts = VALUES(last_purchase_ts);

-- RUN 2: load only new 2018 rows, using the watermark with a 1-day lookback.
INSERT INTO fact_sales (
    order_id, order_item_id, customer_key, product_key, seller_key,
    date_key, payment_type_key, price, freight_value, item_count, order_status
)
SELECT
    i.order_id, i.order_item_id, c.customer_key, p.product_key, s.seller_key,
    DATE_FORMAT(o.order_purchase_timestamp, '%Y%m%d'),
    pt.payment_type_key, i.price, i.freight_value, 1, o.order_status
FROM stg_order_items_inc i
JOIN stg_orders_inc o ON o.order_id = i.order_id
JOIN dim_customer c ON c.customer_id = o.customer_id
JOIN dim_product p ON p.product_id = i.product_id
JOIN dim_seller s ON s.seller_id = i.seller_id
LEFT JOIN (
    SELECT order_id, payment_type FROM (
        SELECT order_id, payment_type,
               ROW_NUMBER() OVER (PARTITION BY order_id ORDER BY payment_sequential) AS rn
        FROM stg_order_payments_inc
    ) ranked WHERE rn = 1
) first_pay ON first_pay.order_id = i.order_id
LEFT JOIN dim_payment_type pt ON pt.payment_type = first_pay.payment_type
CROSS JOIN etl_watermark w
WHERE w.process_name = 'sales_load'
  AND o.order_purchase_timestamp >= '2018-01-01'
  AND o.order_purchase_timestamp <  '2019-01-01'
  AND o.order_purchase_timestamp > DATE_SUB(w.last_purchase_ts, INTERVAL 1 DAY)
  AND NOT EXISTS (
      SELECT 1 FROM fact_sales f
      WHERE f.order_id = i.order_id AND f.order_item_id = i.order_item_id
  );

UPDATE etl_watermark
SET last_purchase_ts = '2018-12-31 23:59:59'
WHERE process_name = 'sales_load';

SELECT process_name, last_purchase_ts FROM etl_watermark;
SELECT YEAR(STR_TO_DATE(date_key, '%Y%m%d')) AS sales_year, COUNT(*) AS items
FROM fact_sales GROUP BY YEAR(STR_TO_DATE(date_key, '%Y%m%d'));

-- Verification queries for the incremental load.
SELECT YEAR(o.order_purchase_timestamp) AS source_year, COUNT(*) AS source_orders
FROM stg_orders_inc o
GROUP BY YEAR(o.order_purchase_timestamp)
ORDER BY source_year;

SELECT COUNT(*) AS fact_rows,
       COUNT(DISTINCT order_id, order_item_id) AS distinct_order_items
FROM fact_sales;

SELECT order_id, order_item_id, COUNT(*) AS copies
FROM fact_sales
GROUP BY order_id, order_item_id
HAVING COUNT(*) > 1
LIMIT 10;
