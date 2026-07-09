"""Fit the 400F SOC datasets with the distinct equivalent-circuit model."""

import sys
from pathlib import Path

repo_root = Path(__file__).resolve().parents[2]
sys.path.insert(0, str(repo_root))

from eis_fit import FitConfig, run_soc_folder


config = FitConfig(
    circuit='R_1-Wo_1-p(CPE_1,R_2-CPE_2)',
    initial_guess=[
        2.51869225e-05,
        4.23861845e-04,
        2.86551216e-01,
        7.76924634e+02,
        2.73551008e-02,
        5.26072604e+03,
        6.17773446e+02,
        1.91755805e+02,
    ],
    bounds=(
        [0, 0, 0, 0, 0.5, 0, 1e-1, 0.5],
        [10e-2, float('inf'), float('inf'), 10000, 1, 100, 1e6, 1],
    ),
    parameter_names=[
        'R_s',
        'Wo_Zo',
        'Wo_T',
        'CPE_H',
        'alpha_H',
        'R_int',
        'CPE_ads',
        'alpha_ads',
    ],
    fit_method='custom_circuit',
    include_parameter_errors=False,
)


if __name__ == '__main__':
    run_soc_folder(Path(__file__).resolve().parent, config)
