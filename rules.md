# Rules for the next agent

These tasks are beginner exercises. Keep the code simple and easy to read. Do not over-engineer.

## The basic pattern

1. Do the days in order: finish Day 2, then Day 3, then Day 4, and so on.
2. Use the venv in the project folder:
   `C:\Users\Kiruthik Kumar\Project\tap-python\venv\Scripts\python.exe`
   Install anything missing with `& "venv\Scripts\python.exe" -m pip install <name>`.
3. Make one folder per day: `Day 2`, `Day 3`, `Day 4`, ... (with a space in the name).
4. In each folder make one notebook: `day12.ipynb`, `day13.ipynb`, `day14.ipynb`, ...
5. The notebook has exactly 10 code cells — one for each numbered task.
6. The first line of every cell is a comment with the task text:
   `# Task 3: Write read_csv(path) returning a list of dictionaries`
7. Ignore the "Tool: ..." and "Dataset: ..." lines at the top of the task. Setup is already
   done, so don't make cells for it.
8. Only make extra files when the task asks for them. Day 2 asks for `reader.py`,
   `validator.py`, `transformer.py`, `test_pipeline.py` and `column_mapping.json`. Day 3 asks
   for `bad_records.csv` and `validation_config.json`. Day 4 asks for `config.yaml`,
   `pipeline.py`, the output files and the manifest. Don't invent other files.
9. Run the whole notebook after writing it so the outputs are saved in the notebook.

## How to write the code

- Write it like a student: plain `for` loops, simple `if` statements, plain dictionaries and
  lists, `print()` for notebook output.
- No fancy classes, no big abstractions, no extra error handling beyond what the task asks for.
- A task that just says "open a PR" or "merge" only needs a short note cell.
- Modules should be generated from the first notebook cell with
  `Path("file.py").write_text('''...''')` so the notebook is the source of truth.
- Keep type hints and docstrings only on Day 2, because that task asks for them.
- Use `logging` in Day 4 (INFO, WARNING, ERROR) instead of `print` inside `pipeline.py`.

## Dataset

The CSVs are in `archive/` at the repo root. From a day folder use `../archive/<file>.csv`.
Useful files: `olist_order_items_dataset.csv`, `olist_orders_dataset.csv`,
`olist_customers_dataset.csv`. Read with `encoding="utf-8-sig"` to avoid BOM problems.

## Day-specific notes

- Day 2: load modules with `%load_ext autoreload` and `%autoreload 2`; run `!pytest -q` in the
  test cell (3 tests must pass); save the column mapping to `column_mapping.json`.
- Day 3: keep all validation code inside the notebook; write rejected rows to
  `bad_records.csv`; allowed order statuses include `unavailable` and `invoiced` too, so the
  clean Olist data gives 0 rejections.
- Day 4: `config.yaml` holds paths, `max_rejected_ratio` and the mapping; `pipeline.py` has one
  `run_pipeline()` function; cell 7 runs it once and cell 10 runs it again to show 0 new files;
  cell 6 resets `manifest.json` so the notebook can be re-run; run `!ruff check pipeline.py` and
  fix anything it reports (use `logger = logging.getLogger(...)` instead of `logging.info(...)`).

## Git

- Don't commit unless the task says to (for example "open a PR" or "merge").
- The repo already has unrelated dirty files (`main.py`, `sample.ipynb`, `archive/`,
  `.openidea/`). Never stage them. Stage only the files for the day you worked on.
- If the T3 PR/merge tools say the token can't access the resource, use the git HTTPS credential
  with the GitHub API and never print the token.
- PR #2 (Day 2 + Day 3) had no review comments and was merged into `main`.

## Finishing up

Check that all cells ran without errors, then tell the user the notebook path and the key
results (tests passed, lint passed, first run vs second run counts). Keep the message short.
