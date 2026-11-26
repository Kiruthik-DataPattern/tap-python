-- Reviews have their own grain: one row per review, not per order item.
-- Run build_tables.sql first so the staging tables and dim_product exist.

DROP TABLE IF EXISTS fact_reviews;

CREATE TABLE fact_reviews (
    review_key BIGINT AUTO_INCREMENT PRIMARY KEY,
    review_id CHAR(32),
    order_id CHAR(32),
    product_key INT,
    date_key INT,
    review_score TINYINT,
    has_comment BOOLEAN,
    answer_date_key INT,
    UNIQUE KEY uq_review (review_id)
);

CREATE TABLE IF NOT EXISTS stg_order_reviews (
    review_id CHAR(32), order_id CHAR(32), review_score TINYINT,
    review_comment_title VARCHAR(200), review_comment_message TEXT,
    review_creation_date DATETIME, review_answer_timestamp DATETIME
);

LOAD DATA LOCAL INFILE 'C:/path/archive/olist_order_reviews_dataset.csv'
INTO TABLE stg_order_reviews FIELDS TERMINATED BY ',' OPTIONALLY ENCLOSED BY '"'
LINES TERMINATED BY '\n' IGNORE 1 LINES;

INSERT INTO fact_reviews (
    review_id, order_id, product_key, date_key,
    review_score, has_comment, answer_date_key
)
SELECT
    r.review_id, r.order_id, p.product_key,
    DATE_FORMAT(r.review_creation_date, '%Y%m%d'),
    r.review_score,
    CASE WHEN r.review_comment_message IS NULL OR r.review_comment_message = '' THEN 0 ELSE 1 END,
    DATE_FORMAT(r.review_answer_timestamp, '%Y%m%d')
FROM stg_order_reviews r
LEFT JOIN stg_order_items i ON i.order_id = r.order_id AND i.order_item_id = 1
LEFT JOIN dim_product p ON p.product_id = i.product_id;
