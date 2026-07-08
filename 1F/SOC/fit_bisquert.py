"""Fit the 1F SOC datasets with a Bisquert open-circuit model."""

import sys
from pathlib import Path

repo_root = Path(__file__).resolve().parents[2]
sys.path.insert(0, str(repo_root))

from eis_fit import FitConfig, run_soc_folder


config = FitConfig(
    circuit='R_0-B_1',
    initial_guess=[0.05, 0.1, 1e20, 1, 0.9, 10],
    bounds=(
        [0, 0, 0, 0, 0.5, 0],
        [float('inf'), float('inf'), float('inf'), float('inf'), 1, float('inf')],
    ),
    parameter_names=['R_0', 'B_1_0', 'B_1_1', 'B_1_2', 'B_1_3', 'B_1_4'],
)


if __name__ == '__main__':
    run_soc_folder(Path(__file__).resolve().parent, config)
