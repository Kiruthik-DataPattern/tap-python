"""A simple pipeline that logs what it does."""
import csv
import json
import logging
import time
from datetime import datetime
from pathlib import Path

import yaml

logger = logging.getLogger("pipeline")


def run_pipeline(config_path="config.yaml"):
    """Read new files, clean them and write the outputs."""
    start = time.time()
    with open(config_path) as file:
        config = yaml.safe_load(file)
    paths = config["paths"]

    run_id = datetime.now().strftime("%Y%m%d_%H%M%S")
    log_file = Path(paths["log_dir"]) / ("run_" + run_id + ".log")
    log_file.parent.mkdir(parents=True, exist_ok=True)
    logging.basicConfig(
        filename=log_file,
        level=logging.INFO,
        format="%(asctime)s %(levelname)s %(message)s",
        force=True,
    )
    logger.info("Starting run %s", run_id)

    manifest_path = Path(paths["manifest"])
    if manifest_path.exists():
        with open(manifest_path) as file:
            manifest = json.load(file)
    else:
        manifest = {"processed": []}

    rows = []
    for source in paths["input_files"]:
        if source in manifest["processed"]:
            logger.info("Skipping %s", source)
            continue
        with open(source, newline="", encoding="utf-8-sig") as file:
            new_rows = list(csv.DictReader(file))
        logger.info("Read %d rows from %s", len(new_rows), source)
        for row in new_rows:
            for old, new in config["mapping"].items():
                if old in row:
                    row[new] = row.pop(old)
            if row.get("price"):
                row["price"] = float(row["price"])
            if row.get("freight"):
                row["freight"] = float(row["freight"])
            rows.append(row)
        manifest["processed"].append(source)

    if rows:
        Path(paths["clean_csv"]).parent.mkdir(parents=True, exist_ok=True)
        with open(paths["clean_csv"], "w", newline="", encoding="utf-8") as file:
            writer = csv.DictWriter(file, fieldnames=list(rows[0].keys()))
            writer.writeheader()
            writer.writerows(rows)
        with open(paths["clean_json"], "w", encoding="utf-8") as file:
            json.dump(rows, file)
        with open(manifest_path, "w") as file:
            json.dump(manifest, file)
        logger.info("Wrote %d clean rows", len(rows))
    else:
        logger.warning("No new files to process")

    summary = {
        "run_id": run_id,
        "rows": len(rows),
        "seconds": round(time.time() - start, 2),
        "log": str(log_file),
    }
    Path(paths["summary_json"]).parent.mkdir(parents=True, exist_ok=True)
    with open(paths["summary_json"], "w") as file:
        json.dump(summary, file)
    logger.info("Finished run %s", run_id)
    return summary
