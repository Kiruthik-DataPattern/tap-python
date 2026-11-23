"""Read a CSV file."""
import csv


def read_csv(path: str) -> list[dict]:
    """Return the rows of a CSV file as a list of dictionaries."""
    rows = []
    with open(path, newline="", encoding="utf-8-sig") as file:
        for row in csv.DictReader(file):
            rows.append(dict(row))
    return rows
