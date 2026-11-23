"""Lightweight validation helpers shared by the pipeline."""

from typing import Any, Dict, Iterable, List


def validate_required_columns(
    records: List[Dict[str, Any]], required: Iterable[str]
) -> List[str]:
    """Return required column names that are absent from the records.

    Args:
        records: Rows to inspect (a list of dictionaries).
        required: Column names that must be present.

    Returns:
        A list of missing column names, in the order they were requested.
    """
    present = set(records[0]) if records else set()
    return [name for name in required if name not in present]
