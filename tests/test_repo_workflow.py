"""Tests for the EIS fitting and plotting repo."""

import importlib.util
import sys
import unittest
from pathlib import Path

import numpy as np

REPO_ROOT = Path(__file__).resolve().parents[1]
sys.path.insert(0, str(REPO_ROOT))

from eis_fit import FitConfig, circuit_elements, iter_python_csvs, load_impedance


FIT_WRAPPERS = [
    "1F/SOC/fit_bisquert.py",
    "1F/SOC/fit_distinct.py",
    "1F/SOC/fit_bisquert_cutoff.py",
    "60F/SOC/fit_bisquert.py",
    "400F/SOC/fit_bisquert.py",
    "400F/SOC/fit_distinct.py",
]

TABLE_WRAPPERS = [
    "1F/SOC/write_fit_tables.py",
    "1F/SOC/write_params_bisquert.py",
    "1F/SOC/write_params_distinct.py",
    "60F/SOC/write_fit_tables.py",
    "60F/SOC/write_params_bisquert.py",
    "400F/SOC/write_fit_tables.py",
    "400F/SOC/write_params_bisquert.py",
    "400F/SOC/write_params_distinct.py",
]

MATLAB_ENTRYPOINTS = [
    "1F/SOC/SOCPlot.m",
    "1F/SOC/SOCFitPlot.m",
    "60F/SOC/SOCPlot.m",
    "60F/SOC/SOCFitPlot.m",
    "400F/SOC/SOCPlot.m",
    "400F/SOC/SOCFitPlot.m",
]


def load_module(relative_path):
    """Import a repo script without running its __main__ block."""
    path = REPO_ROOT / relative_path
    module_name = relative_path.replace("/", "_").replace(".", "_").replace("%", "pct")
    spec = importlib.util.spec_from_file_location(module_name, path)
    module = importlib.util.module_from_spec(spec)
    spec.loader.exec_module(module)
    return module


class RepoSmokeTests(unittest.TestCase):
    def test_fit_wrappers_define_configs(self):
        for wrapper in FIT_WRAPPERS:
            with self.subTest(wrapper=wrapper):
                module = load_module(wrapper)

                self.assertIsInstance(module.config, FitConfig)
                self.assertEqual(
                    len(module.config.initial_guess),
                    len(module.config.parameter_names),
                )

    def test_table_wrappers_import_without_running(self):
        for wrapper in TABLE_WRAPPERS:
            with self.subTest(wrapper=wrapper):
                module = load_module(wrapper)
                public_names = [name for name in dir(module) if name.startswith("write_")]

                self.assertTrue(public_names)

    def test_sample_python_csv_can_be_read(self):
        csv_file = REPO_ROOT / "1F/SOC/100%SOC/1F-100%SOC_Python.csv"
        frequencies, impedance = load_impedance(csv_file)

        self.assertGreater(len(frequencies), 0)
        self.assertEqual(len(frequencies), len(impedance))
        self.assertTrue(np.iscomplexobj(impedance))

    def test_soc_folders_are_discovered(self):
        files = list(iter_python_csvs(REPO_ROOT / "400F/SOC"))

        self.assertGreaterEqual(len(files), 6)
        self.assertTrue(all(str(csv_file).endswith("_Python.csv") for _, csv_file in files))

    def test_bisquert_linnkk_numpy_alias_is_registered(self):
        self.assertIs(circuit_elements["np"], np)

    def test_extraction_script_is_the_clean_function_name(self):
        text = (REPO_ROOT / "extract_nyquist_all_soc.m").read_text(encoding="utf-8")

        self.assertIn("function extract_nyquist_all_soc", text)
        self.assertIn("frequency = data{:, 6};  % Hz", text)

    def test_matlab_entrypoints_call_shared_helpers(self):
        for entrypoint in MATLAB_ENTRYPOINTS:
            with self.subTest(entrypoint=entrypoint):
                text = (REPO_ROOT / entrypoint).read_text(encoding="utf-8")

                self.assertIn("plotting", text)
                self.assertTrue(
                    "plot_soc_measured" in text or "plot_soc_fit" in text,
                    msg=f"{entrypoint} should call a shared MATLAB plot helper",
                )


if __name__ == "__main__":
    unittest.main()
