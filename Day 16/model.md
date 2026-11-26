# The Olist sales model, in plain words

## Grain of fact_sales

One row = one item on one order. If a customer buys three items, `fact_sales` gets three rows.

I did not make it one row per order because price, freight and seller are different for every item. Rolling up to the order would hide exactly the detail leadership asks for: which product sold, which seller shipped it, and how much freight it cost.

## Measures (the numbers we add up)

- `price` - what the item sold for
- `freight_value` - shipping cost for that item
- `item_value` - simply price + freight, handy for quick reports
- `item_count` - always 1 per row, so we can count items with SUM instead of COUNT

I deliberately left `payment_value` out of `fact_sales`. Payments are stored per order, not per item, so putting that number on each item row would double count it. It belongs in its own payment fact if we need it later.

## Dimensions (the "by" columns)

- **customer** - who bought: customer id, unique id, zip prefix, city, state
- **product** - what was bought: product id, category (English name if we have it), size and weight
- **seller** - who sold it: seller id, zip prefix, city, state
- **date** - when it happened: based on `order_purchase_timestamp`, with month, quarter, year and weekday ready for reports
- **payment type** - how they paid: credit card, boleto, voucher or debit card

Each dimension has one row per thing, and `fact_sales` keeps only a small key that points back to it.

## Surrogate keys vs natural keys

Olist gives us natural keys such as `order_id` and `product_id`, and they are 32-character hex strings. I keep those in the dimensions so we can always trace a row back to the source CSV.

In `fact_sales` I use small integer **surrogate** keys instead. Two reasons: storing a 32-character string millions of times is wasteful, and if Olist ever changes its ID format the surrogate key does not change, so the warehouse stays stable.

For `dim_date` I use `YYYYMMDD` as the key. It is technically a smart surrogate key, but it is short, sortable and easy for a human to read in a report. `dim_payment_type` gets a tiny integer key because the natural value is a long word like `credit_card`.
