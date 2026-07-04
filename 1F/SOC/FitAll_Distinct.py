"""Fit the 1F SOC datasets with the distinct equivalent-circuit model."""

import sys
from pathlib import Path

repo_root = Path(__file__).resolve().parents[2]
sys.path.insert(0, str(repo_root))

from eis_fit_workflow import FitConfig, run_soc_folder


config = FitConfig(
    circuit='R_1-Wo_1-p(CPE_1,R_2-CPE_2)',
    initial_guess=[
        5.51731416e-02,
        2.62415249e-01,
        2.86877603e-01,
        4.03352192e-04,
        9.99239049e-01,
        3.99821566e-02,
        2.17717863e+01,
        4.19073668e-01,
    ],
    bounds=(
        [1e-2, 0, 0, 0, 0.5, 0, 1e-1, 0.5],
        [10e-2, float('inf'), float('inf'), 10, 1, 0.1, 1e3, 1],
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
    include_parameter_errors=False,
    cutoff_frequency=100e-3,  # Hz
)


if __name__ == '__main__':
    run_soc_folder(Path(__file__).resolve().parent, config)
