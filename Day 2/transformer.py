"""Rename columns and change their values."""
from datetime import datetime

COLUMN_MAPPING = {
    "order_id": "order_id",
    "freight_value": "freight",
    "price": "price",
    "shipping_limit_date": "shipping_limit_date",
}

TIMESTAMP_COLUMNS = ["shipping_limit_date", "order_purchase_timestamp"]


def to_snake_case(name: str) -> str:
    """Change a column name to snake_case."""
    return name.strip().lower().replace(" ", "_").replace("-", "_").replace(".", "_")


def map_columns(rows: list[dict], mapping: dict) -> list[dict]:
    """Rename the columns using a dictionary."""
    new_rows = []
    for row in rows:
        new_row = {}
        for key, value in row.items():
            new_row[mapping.get(key, key)] = value
        new_rows.append(new_row)
    return new_rows


def convert_types(rows: list[dict]) -> list[dict]:
    """Make price and freight floats and the dates datetimes."""
    for row in rows:
        row["price"] = float(row["price"])
        row["freight"] = float(row["freight"])
        for name in TIMESTAMP_COLUMNS:
            if row.get(name):
                row[name] = datetime.strptime(row[name], "%Y-%m-%d %H:%M:%S")
    return rows


def calculate_order_totals(rows: list[dict]) -> dict:
    """Add price and freight for every order id."""
    totals = {}
    for row in rows:
        order_id = row["order_id"]
        if order_id not in totals:
            totals[order_id] = 0
        totals[order_id] += float(row["price"]) + float(row["freight"])
    return totals
