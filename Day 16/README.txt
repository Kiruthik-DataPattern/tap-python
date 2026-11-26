DAY 16 - OLIST WAREHOUSE MODEL

These notes are kept as plain text on purpose. No markdown, no fancy formatting.

MySQL Workbench and draw.io are desktop GUI tools, so I did not use them here.
The diagram is drawn with plain text characters in star_schema.txt and the
database work is written as SQL files. The mysql command line is not installed
in this environment, so the SQL is ready to run but was not run locally.

FILES

README.txt              this file
business_questions.txt  8 questions leadership would ask
model.txt               grain, measures, dimensions and keys
star_schema.txt         simple text star diagram
dim_date.sql            recursive CTE for the date dimension
build_tables.sql        staging tables, dimensions and fact_sales
check_totals.sql        SQL to compare fact totals with source totals
fact_reviews.sql        reviews as a separate fact
fact_reviews.txt        why reviews are a separate fact
