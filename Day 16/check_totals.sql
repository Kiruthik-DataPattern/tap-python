-- Run both queries after build_tables.sql. The three numbers should match.

SELECT COUNT(*) AS fact_items,
       ROUND(SUM(price), 2) AS fact_price,
       ROUND(SUM(freight_value), 2) AS fact_freight
FROM fact_sales;

SELECT COUNT(*) AS source_items,
       ROUND(SUM(price), 2) AS source_price,
       ROUND(SUM(freight_value), 2) AS source_freight
FROM stg_order_items;
