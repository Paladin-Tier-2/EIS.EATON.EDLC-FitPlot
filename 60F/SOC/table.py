"""Write 60F fit-quality LaTeX tables."""

import sys
from pathlib import Path

repo_root = Path(__file__).resolve().parents[2]
sys.path.insert(0, str(repo_root))

from eis_table_workflow import write_fit_quality_tables


if __name__ == '__main__':
    write_fit_quality_tables(Path(__file__).resolve().parent)
