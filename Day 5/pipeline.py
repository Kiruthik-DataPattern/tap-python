"""Simple Day 5 pipeline."""
import csv
import glob
import json
import logging
import os
import time
from datetime import datetime

import yaml

logger = logging.getLogger("day5")


class SchemaError(Exception):
    """A file is missing a required column."""


class FileFormatError(Exception):
    """A file cannot be read or is empty."""


def load_config(path="config.yaml"):
    """Read the YAML config file."""
    with open(path) as file:
        return yaml.safe_load(file)


def read_csv(path, delimiter=","):
    """Return the rows of one CSV file."""
    rows = []
    with open(path, newline="", encoding="utf-8-sig") as file:
        reader = csv.DictReader(file, delimiter=delimiter)
        if not reader.fieldnames:
            raise FileFormatError("Empty file: " + path)
        for row in reader:
            rows.append(dict(row))
    return rows


def find_files(config):
    """Find every CSV in the folders listed in the config."""
    files = []
    for folder in config["paths"]["data_dirs"]:
        files += sorted(glob.glob(folder + "/*.csv"))
    return files


def apply_mapping(name, rows, config):
    """Rename columns using the mapping for this file."""
    mapping = config["mapping"].get(name, {})
    new_rows = []
    for row in rows:
        new_row = {}
        for key, value in row.items():
            new_row[mapping.get(key, key)] = value
        new_rows.append(new_row)
    return new_rows


def validate_row(row, required):
    """Return a list of problems with one row."""
    errors = []
    for field in required:
        if not row.get(field):
            errors.append("missing " + field)
    return errors


def write_bad_records(bad_rows, path):
    """Write rejected rows and the reason to a CSV file."""
    with open(path, "w", newline="", encoding="utf-8") as file:
        writer = csv.writer(file)
        writer.writerow(["file", "row", "reason"])
        for name, row, reason in bad_rows:
            writer.writerow([name, row, "; ".join(reason)])
    return len(bad_rows)


def run_pipeline(config_path="config.yaml"):
    """Read new files, validate them and write the outputs."""
    start = time.time()
    config = load_config(config_path)
    paths = config["paths"]
    run_id = datetime.now().strftime("%Y%m%d_%H%M%S")
    os.makedirs(paths["log_dir"], exist_ok=True)
    log_file = paths["log_dir"] + "/run_" + run_id + ".log"
    logging.basicConfig(
        filename=log_file,
        level=logging.INFO,
        format="%(asctime)s %(levelname)s %(message)s",
        force=True,
    )
    logger.info("Starting run %s", run_id)

    first_run = not os.path.exists(paths["manifest"])
    if os.path.exists(paths["manifest"]):
        with open(paths["manifest"]) as file:
            manifest = json.load(file)
    else:
        manifest = {"processed": []}

    clean_rows = []
    bad_rows = []
    new_files = []
    for path in find_files(config):
        name = os.path.basename(path)
        if name in manifest["processed"]:
            logger.info("Skipping %s", name)
            continue
        try:
            with open(path, encoding="utf-8-sig") as file:
                first_line = file.readline()
            delimiter = ";" if ";" in first_line else ","
            rows = read_csv(path, delimiter)
            if not rows:
                raise FileFormatError("No data rows in " + name)
        except (OSError, FileFormatError) as error:
            logger.warning("Could not read %s: %s", name, error)
            continue

        required = config["required"].get(name, [])
        for column in required:
            if column not in rows[0]:
                raise SchemaError(name + " is missing " + column)
        file_clean = []
        for row in rows:
            errors = validate_row(row, required)
            if errors:
                bad_rows.append((name, row, errors))
            else:
                file_clean.append(row)
        clean_rows.extend(apply_mapping(name, file_clean, config))
        manifest["processed"].append(name)
        new_files.append(name)
        logger.info("Read %d rows from %s", len(rows), name)

    os.makedirs("outputs", exist_ok=True)
    write_bad_records(bad_rows, paths["bad_csv"])
    if new_files:
        with open(paths["manifest"], "w") as file:
            json.dump(manifest, file)
    if first_run:
        with open(paths["clean_csv"], "w", newline="", encoding="utf-8") as file:
            columns = sorted({key for row in clean_rows for key in row})
            writer = csv.DictWriter(file, fieldnames=columns)
            writer.writeheader()
            writer.writerows(clean_rows)
        with open(paths["clean_json"], "w", encoding="utf-8") as file:
            json.dump(clean_rows, file)
    summary = {
        "run_id": run_id,
        "new_files": len(new_files),
        "clean_rows": len(clean_rows),
        "bad_rows": len(bad_rows),
        "seconds": round(time.time() - start, 2),
        "log": log_file,
    }
    with open(paths["summary_json"], "w") as file:
        json.dump(summary, file)
    logger.info("Done %s", summary)
    return summary
