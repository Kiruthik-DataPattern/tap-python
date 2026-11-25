import pipeline


def test_read_csv(tmp_path):
    file = tmp_path / "x.csv"
    file.write_text("a,b\n1,2\n")
    assert pipeline.read_csv(str(file)) == [{"a": "1", "b": "2"}]


def test_read_csv_semicolon(tmp_path):
    file = tmp_path / "x.csv"
    file.write_text("a;b\n1;2\n")
    assert pipeline.read_csv(str(file), ";") == [{"a": "1", "b": "2"}]


def test_apply_mapping():
    rows = [{"order_id": "1", "freight_value": "5"}]
    config = {"mapping": {"f.csv": {"freight_value": "freight"}}}
    assert pipeline.apply_mapping("f.csv", rows, config) == [
        {"order_id": "1", "freight": "5"}
    ]


def test_validate_row():
    assert pipeline.validate_row({"order_id": "1"}, ["order_id", "price"]) == ["missing price"]


def test_custom_exceptions():
    try:
        raise pipeline.SchemaError("bad schema")
    except pipeline.SchemaError as error:
        assert str(error) == "bad schema"


def test_write_bad_records(tmp_path):
    path = tmp_path / "bad.csv"
    count = pipeline.write_bad_records([("f.csv", {"a": "1"}, ["missing b"])], str(path))
    assert count == 1
    assert "missing b" in path.read_text()
