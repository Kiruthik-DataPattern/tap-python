import pytest

from reader import read_csv
from transformer import calculate_order_totals, to_snake_case


def test_read_csv_returns_list_of_dicts(tmp_path):
    csv_file = tmp_path / "sample.csv"
    csv_file.write_text("a,b\n1,2\n3,4\n", encoding="utf-8")
    rows = read_csv(str(csv_file))
    assert rows == [{"a": "1", "b": "2"}, {"a": "3", "b": "4"}]


def test_to_snake_case():
    assert to_snake_case("Freight Value") == "freight_value"
    assert to_snake_case("orderID") == "order_id"
    assert to_snake_case("Product-Category.Name") == "product_category_name"


def test_calculate_order_totals():
    rows = [
        {"order_id": "A", "price": 10.0, "freight": 2.0},
        {"order_id": "A", "price": 5.0, "freight": 1.0},
        {"order_id": "B", "price": 7.0, "freight": 3.0},
    ]
    assert calculate_order_totals(rows) == {"A": 18.0, "B": 10.0}
