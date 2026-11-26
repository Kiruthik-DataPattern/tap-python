# Day 16 - Olist warehouse model

I kept this simple and human. The answers to the "thinking" questions are in Markdown files; the database work is in `.sql` files.

Files:
- `business_questions.md` - the 8 questions leadership would ask
- `model.md` - grain, measures, dimensions and keys
- `star_schema.md` - the star diagram in Mermaid (draw.io replacement)
- `dim_date.sql` - recursive CTE for the date dimension
- `build_tables.sql` - staging tables, dimensions and `fact_sales`
- `check_totals.sql` - SQL to compare fact totals with source totals
- `fact_reviews.sql` and `fact_reviews.md` - reviews as a separate fact

Note: MySQL Workbench and draw.io are desktop GUI tools and are out of scope here. I wrote the diagram as Mermaid and the database work as plain SQL instead. The `mysql` command line is also not installed locally, so the SQL is ready to run but was not executed in this environment.
