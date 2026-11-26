# Star schema

draw.io is a desktop app, so I drew this as a Mermaid diagram. It shows the same thing: one fact table in the middle with five dimensions around it.

```mermaid
erDiagram
    dim_customer ||--o{ fact_sales : "customer_key"
    dim_product  ||--o{ fact_sales : "product_key"
    dim_seller   ||--o{ fact_sales : "seller_key"
    dim_date     ||--o{ fact_sales : "date_key"
    dim_payment_type ||--o{ fact_sales : "payment_type_key"
    dim_date     ||--o{ fact_reviews : "date_key"
    dim_product  ||--o{ fact_reviews : "product_key"
```

The `||--o{` symbol means "one dimension row connects to many fact rows". For example, one customer can have many sales rows.

`fact_reviews` sits next to the star because it answers different questions (see `fact_reviews.md`).
