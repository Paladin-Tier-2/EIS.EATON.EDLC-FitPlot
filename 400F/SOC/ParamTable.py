"""Write the 400F Bisquert parameter LaTeX table."""

import sys
from pathlib import Path

repo_root = Path(__file__).resolve().parents[2]
sys.path.insert(0, str(repo_root))

from eis_table_workflow import write_bisquert_param_table


if __name__ == '__main__':
    write_bisquert_param_table(Path(__file__).resolve().parent)
