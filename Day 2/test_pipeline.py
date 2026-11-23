from reader import read_csv
from transformer import calculate_order_totals, to_snake_case


def test_read_csv(tmp_path):
    file = tmp_path / "x.csv"
    file.write_text("a,b\n1,2\n")
    assert read_csv(str(file)) == [{"a": "1", "b": "2"}]


def test_to_snake_case():
    assert to_snake_case("Freight Value") == "freight_value"


def test_calculate_order_totals():
    rows = [
        {"order_id": "A", "price": 10, "freight": 2},
        {"order_id": "A", "price": 5, "freight": 1},
    ]
    assert calculate_order_totals(rows) == {"A": 18}
