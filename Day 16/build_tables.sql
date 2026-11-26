-- Run dim_date.sql first. Then run this script in MySQL Workbench.
-- Change the folder in each LOAD DATA line to where you keep the Olist CSVs.
-- LOAD DATA LOCAL INFILE needs the local_infile option enabled on the server/client.

DROP TABLE IF EXISTS fact_sales;
DROP TABLE IF EXISTS dim_customer;
DROP TABLE IF EXISTS dim_product;
DROP TABLE IF EXISTS dim_seller;
DROP TABLE IF EXISTS dim_payment_type;

CREATE TABLE dim_customer (
    customer_key INT AUTO_INCREMENT PRIMARY KEY,
    customer_id CHAR(32),
    customer_unique_id CHAR(32),
    zip_prefix VARCHAR(5),
    city VARCHAR(100),
    state VARCHAR(2)
);

CREATE TABLE dim_product (
    product_key INT AUTO_INCREMENT PRIMARY KEY,
    product_id CHAR(32),
    category_name VARCHAR(100),
    category_name_english VARCHAR(100),
    weight_g INT,
    length_cm INT,
    height_cm INT,
    width_cm INT
);

CREATE TABLE dim_seller (
    seller_key INT AUTO_INCREMENT PRIMARY KEY,
    seller_id CHAR(32),
    zip_prefix VARCHAR(5),
    city VARCHAR(100),
    state VARCHAR(2)
);

CREATE TABLE dim_payment_type (
    payment_type_key INT AUTO_INCREMENT PRIMARY KEY,
    payment_type VARCHAR(30)
);

CREATE TABLE fact_sales (
    sales_key BIGINT AUTO_INCREMENT PRIMARY KEY,
    order_id CHAR(32),
    order_item_id INT,
    customer_key INT,
    product_key INT,
    seller_key INT,
    date_key INT,
    payment_type_key INT,
    price DECIMAL(10,2),
    freight_value DECIMAL(10,2),
    item_count TINYINT DEFAULT 1,
    order_status VARCHAR(30),
    UNIQUE KEY uq_order_item (order_id, order_item_id)
);

-- Staging tables: plain copies of the CSV files.
DROP TABLE IF EXISTS stg_order_items;
CREATE TABLE stg_order_items (
    order_id CHAR(32), order_item_id INT, product_id CHAR(32), seller_id CHAR(32),
    shipping_limit_date DATETIME, price DECIMAL(10,2), freight_value DECIMAL(10,2)
);
LOAD DATA LOCAL INFILE 'C:/path/archive/olist_order_items_dataset.csv'
INTO TABLE stg_order_items FIELDS TERMINATED BY ',' OPTIONALLY ENCLOSED BY '"'
LINES TERMINATED BY '\n' IGNORE 1 LINES;

DROP TABLE IF EXISTS stg_orders;
CREATE TABLE stg_orders (
    order_id CHAR(32), customer_id CHAR(32), order_status VARCHAR(30),
    order_purchase_timestamp DATETIME, order_approved_at DATETIME,
    order_delivered_carrier_date DATETIME, order_delivered_customer_date DATETIME,
    order_estimated_delivery_date DATETIME
);
LOAD DATA LOCAL INFILE 'C:/path/archive/olist_orders_dataset.csv'
INTO TABLE stg_orders FIELDS TERMINATED BY ',' OPTIONALLY ENCLOSED BY '"'
LINES TERMINATED BY '\n' IGNORE 1 LINES;

DROP TABLE IF EXISTS stg_customers;
CREATE TABLE stg_customers (
    customer_id CHAR(32), customer_unique_id CHAR(32),
    customer_zip_code_prefix VARCHAR(5), customer_city VARCHAR(100), customer_state VARCHAR(2)
);
LOAD DATA LOCAL INFILE 'C:/path/archive/olist_customers_dataset.csv'
INTO TABLE stg_customers FIELDS TERMINATED BY ',' OPTIONALLY ENCLOSED BY '"'
LINES TERMINATED BY '\n' IGNORE 1 LINES;

DROP TABLE IF EXISTS stg_sellers;
CREATE TABLE stg_sellers (
    seller_id CHAR(32), seller_zip_code_prefix VARCHAR(5),
    seller_city VARCHAR(100), seller_state VARCHAR(2)
);
LOAD DATA LOCAL INFILE 'C:/path/archive/olist_sellers_dataset.csv'
INTO TABLE stg_sellers FIELDS TERMINATED BY ',' OPTIONALLY ENCLOSED BY '"'
LINES TERMINATED BY '\n' IGNORE 1 LINES;

DROP TABLE IF EXISTS stg_products;
CREATE TABLE stg_products (
    product_id CHAR(32), product_category_name VARCHAR(100),
    product_name_lenght INT, product_description_lenght INT, product_photos_qty INT,
    product_weight_g INT, product_length_cm INT, product_height_cm INT, product_width_cm INT
);
LOAD DATA LOCAL INFILE 'C:/path/archive/olist_products_dataset.csv'
INTO TABLE stg_products FIELDS TERMINATED BY ',' OPTIONALLY ENCLOSED BY '"'
LINES TERMINATED BY '\n' IGNORE 1 LINES;

DROP TABLE IF EXISTS stg_category_translation;
CREATE TABLE stg_category_translation (
    product_category_name VARCHAR(100), product_category_name_english VARCHAR(100)
);
-- This file has a BOM on the first column; strip it if the first category looks wrong.
LOAD DATA LOCAL INFILE 'C:/path/archive/product_category_name_translation.csv'
INTO TABLE stg_category_translation FIELDS TERMINATED BY ',' OPTIONALLY ENCLOSED BY '"'
LINES TERMINATED BY '\n' IGNORE 1 LINES;

DROP TABLE IF EXISTS stg_order_payments;
CREATE TABLE stg_order_payments (
    order_id CHAR(32), payment_sequential INT, payment_type VARCHAR(30),
    payment_installments INT, payment_value DECIMAL(10,2)
);
LOAD DATA LOCAL INFILE 'C:/path/archive/olist_order_payments_dataset.csv'
INTO TABLE stg_order_payments FIELDS TERMINATED BY ',' OPTIONALLY ENCLOSED BY '"'
LINES TERMINATED BY '\n' IGNORE 1 LINES;

-- Fill the dimensions.
INSERT INTO dim_customer (customer_id, customer_unique_id, zip_prefix, city, state)
SELECT DISTINCT customer_id, customer_unique_id, customer_zip_code_prefix, customer_city, customer_state
FROM stg_customers;

INSERT INTO dim_seller (seller_id, zip_prefix, city, state)
SELECT DISTINCT seller_id, seller_zip_code_prefix, seller_city, seller_state
FROM stg_sellers;

INSERT INTO dim_product (product_id, category_name, category_name_english, weight_g, length_cm, height_cm, width_cm)
SELECT p.product_id, p.product_category_name, t.product_category_name_english,
       p.product_weight_g, p.product_length_cm, p.product_height_cm, p.product_width_cm
FROM stg_products p
LEFT JOIN stg_category_translation t ON t.product_category_name = p.product_category_name;

INSERT INTO dim_payment_type (payment_type)
SELECT DISTINCT payment_type FROM stg_order_payments;

-- Fill the fact. One row per order item, as promised.
-- Payments are per order, so we take the first payment row for each order to avoid duplicating items.
INSERT INTO fact_sales (
    order_id, order_item_id, customer_key, product_key, seller_key,
    date_key, payment_type_key, price, freight_value, item_count, order_status
)
SELECT
    i.order_id, i.order_item_id, c.customer_key, p.product_key, s.seller_key,
    DATE_FORMAT(o.order_purchase_timestamp, '%Y%m%d'),
    pt.payment_type_key,
    i.price, i.freight_value, 1, o.order_status
FROM stg_order_items i
JOIN stg_orders o ON o.order_id = i.order_id
JOIN dim_customer c ON c.customer_id = o.customer_id
JOIN dim_product p ON p.product_id = i.product_id
JOIN dim_seller s ON s.seller_id = i.seller_id
LEFT JOIN (
    SELECT order_id, payment_type FROM (
        SELECT order_id, payment_type,
               ROW_NUMBER() OVER (PARTITION BY order_id ORDER BY payment_sequential) AS rn
        FROM stg_order_payments
    ) ranked
    WHERE rn = 1
) first_pay ON first_pay.order_id = i.order_id
LEFT JOIN dim_payment_type pt ON pt.payment_type = first_pay.payment_type;

SELECT COUNT(*) AS fact_rows FROM fact_sales;
