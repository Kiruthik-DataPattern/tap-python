"""CSV reading utilities for the Olist dataset."""

import csv
from typing import Any, Dict, List


def read_csv(path: str, delimiter: str = ",") -> List[Dict[str, Any]]:
    """Read a CSV file into a list of dictionaries.

    Args:
        path: Path to the CSV file.
        delimiter: Character separating fields in the file.

    Returns:
        One dictionary per data row, keyed by the header column names.

    Raises:
        FileNotFoundError: If the file does not exist.
        ValueError: If the file has no header row.
    """
    with open(path, newline="", encoding="utf-8-sig") as handle:
        reader = csv.DictReader(handle, delimiter=delimiter)
        if reader.fieldnames is None:
            raise ValueError(f"No header row found in {path!r}")
        return [dict(row) for row in reader]
