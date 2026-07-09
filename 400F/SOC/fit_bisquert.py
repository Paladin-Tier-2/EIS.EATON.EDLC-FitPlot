"""Fit the 400F SOC datasets with a Bisquert open-circuit model."""

import sys
from pathlib import Path

repo_root = Path(__file__).resolve().parents[2]
sys.path.insert(0, str(repo_root))

from eis_fit import FitConfig, run_soc_folder


config = FitConfig(
    circuit='R_0-B_1',
    initial_guess=[
        1.95035263e-03,
        2.84343889e-03,
        2.54997737e+03,
        4.13414733e+02,
        9.85521503e-01,
        4.60103438e-02,
    ],
    bounds=(
        [0, 0, 0, 0, 0.5, 0],
        [float('inf'), float('inf'), float('inf'), float('inf'), 1, float('inf')],
    ),
    parameter_names=['R_0', 'B_1_0', 'B_1_1', 'B_1_2', 'B_1_3', 'B_1_4'],
)


if __name__ == '__main__':
    run_soc_folder(Path(__file__).resolve().parent, config)
