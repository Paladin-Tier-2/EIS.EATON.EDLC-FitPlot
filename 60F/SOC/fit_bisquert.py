"""Fit the 60F SOC datasets with a Bisquert open-circuit model."""

import sys
from pathlib import Path

repo_root = Path(__file__).resolve().parents[2]
sys.path.insert(0, str(repo_root))

from eis_fit import FitConfig, run_soc_folder


config = FitConfig(
    circuit='R_0-B_1',
    initial_guess=[7.43197184e-03, 112e-3, 1e32, 60, 9.62423346e-01, 1],
    parameter_names=['R_0', 'B_1_0', 'B_1_1', 'B_1_2', 'B_1_3', 'B_1_4'],
    show_plot=True,
)


if __name__ == '__main__':
    run_soc_folder(Path(__file__).resolve().parent, config)
