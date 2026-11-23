"""Check that the needed columns are there."""


def validate_required_columns(rows: list[dict], required: list) -> list:
    """Return the names of the columns that are missing."""
    missing = []
    for name in required:
        if rows and name not in rows[0]:
            missing.append(name)
    return missing
