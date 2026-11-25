# Day 5 setup

Use the virtual environment already in the project:

    C:\Users\Kiruthik Kumar\Project\tap-python\venv\Scripts\python.exe

Install the extra packages if they are missing:

    & "venv\Scripts\python.exe" -m pip install pytest pyyaml ruff

Start Jupyter from the project folder:

    & "venv\Scripts\jupyter.exe" notebook

Open `Day 5/day15.ipynb` and run all cells. The CSV files are in `archive/`.
The pipeline reads every CSV it finds there, uses `config.yaml` for column
mappings and required fields, and writes results into `outputs/`.
