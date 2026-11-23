"""Schema mapping, type conversion and aggregation helpers."""

import re
from datetime import datetime
from typing import Any, Dict, List

TIMESTAMP_COLUMNS = (
    "shipping_limit_date",
    "order_purchase_timestamp",
    "order_approved_at",
    "order_delivered_carrier_date",
    "order_delivered_customer_date",
    "order_estimated_delivery_date",
    "review_creation_date",
    "review_answer_timestamp",
)

COLUMN_MAPPING: Dict[str, str] = {
    "order_id": "order_id",
    "order_item_id": "order_item_id",
    "product_id": "product_id",
    "seller_id": "seller_id",
    "shipping_limit_date": "shipping_limit_date",
    "price": "price",
    "freight_value": "freight",
}


def to_snake_case(name: str) -> str:
    """Convert a column name to snake_case.

    Args:
        name: Original column name.

    Returns:
        The normalised snake_case name.
    """
    result = re.sub(r"[\-\.\s]+", "_", name.strip())
    result = re.sub(r"(?<=[a-z0-9])(?=[A-Z])", "_", result)
    result = re.sub(r"[^0-9a-zA-Z_]", "", result)
    return re.sub(r"_+", "_", result).strip("_").lower()


def map_columns(
    records: List[Dict[str, Any]], mapping: Dict[str, str]
) -> List[Dict[str, Any]]:
    """Rename columns using a mapping dictionary (unmapped keys are kept).

    Args:
        records: Rows to rename.
        mapping: Source column name -> standard column name.

    Returns:
        A new list of renamed rows.
    """
    return [{mapping.get(key, key): value for key, value in row.items()} for row in records]


def convert_types(records: List[Dict[str, Any]]) -> List[Dict[str, Any]]:
    """Convert price/freight to float and timestamp fields to datetime.

    Args:
        records: Rows with string values coming from the CSV.

    Returns:
        A new list of rows with converted values.
    """
    result: List[Dict[str, Any]] = []
    for row in records:
        converted = dict(row)
        for field in ("price", "freight"):
            if field in converted and converted[field] not in (None, ""):
                converted[field] = float(converted[field])
        for field in TIMESTAMP_COLUMNS:
            value = converted.get(field)
            if isinstance(value, str) and value:
                converted[field] = datetime.strptime(value, "%Y-%m-%d %H:%M:%S")
        result.append(converted)
    return result


def calculate_order_totals(records: List[Dict[str, Any]]) -> Dict[str, float]:
    """Sum price + freight for every order id using a dictionary.

    Args:
        records: Rows containing order_id, price and freight.

    Returns:
        Mapping of order_id to its total amount.
    """
    totals: Dict[str, float] = {}
    for row in records:
        order_id = row["order_id"]
        totals[order_id] = totals.get(order_id, 0.0) + float(row["price"]) + float(row["freight"])
    return totals
