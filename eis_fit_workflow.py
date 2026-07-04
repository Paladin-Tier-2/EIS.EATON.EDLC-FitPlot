"""Shared EIS fitting workflow used by the SOC fitting scripts."""

import glob
import os
from dataclasses import dataclass

import matplotlib.pyplot as plt
import numpy as np
import pandas as pd
from impedance import preprocessing
from impedance.models.circuits import CustomCircuit
from impedance.models.circuits.elements import element
from impedance.models.circuits.fitting import circuit_fit, rmse
from impedance.preprocessing import saveCSV
from impedance.validation import linKK
from impedance.visualization import plot_nyquist, plot_residuals


@dataclass(frozen=True)
class FitConfig:
    """Configuration for one SOC fitting script.

    Parameters
    ----------
    circuit : str
        `impedance.py` circuit string.
    initial_guess : list[float]
        Initial parameter guesses for the circuit fit.
    parameter_names : list[str]
        Names written to the `_Fit_params.csv` output.
    bounds : tuple[list[float], list[float]] or None
        Lower and upper fit bounds. Use `None` when the script should not pass
        bounds to the fitter.
    fit_method : {"circuit_fit", "custom_circuit"}
        Fitting API used by the original script.
    include_parameter_errors : bool
        Whether `_Fit_params.csv` should include an `Error` column.
    cutoff_frequency : float or None
        Minimum frequency to keep before fitting, in Hz.
    show_plot : bool
        Whether to show a diagnostic Nyquist/residual plot for each fit.
    """
    circuit: str
    initial_guess: list
    parameter_names: list
    bounds: tuple | None = None
    fit_method: str = "circuit_fit"
    include_parameter_errors: bool = True
    cutoff_frequency: float | None = None
    show_plot: bool = False


def coth(x):
    """Hyperbolic cotangent used by the Bisquert element.

    Parameters
    ----------
    x : numpy.ndarray
        Complex argument.

    Returns
    -------
    numpy.ndarray
        Hyperbolic cotangent of `x`.
    """
    return 1 / np.tanh(x)


@element(5, units=['Ohm', 'Ohm', '(s^α)/Ω', '', 'm'])
def B(p, f):
    """Bisquert open-circuit element.

    Parameters
    ----------
    p : sequence of float
        Element parameters: `r_m`, `r_k`, `Q`, `alpha`, and `L`.
    f : numpy.ndarray
        Frequency values in Hz.

    Returns
    -------
    numpy.ndarray
        Complex impedance of the Bisquert element.
    """
    j = 1j
    omega = 2 * np.pi * np.array(f)
    term1 = np.sqrt(p[0] / ((1 / p[1]) + (p[2] * ((j * omega) ** p[3]))))
    term2 = p[4] * np.sqrt(p[0] * ((1 / p[1]) + (p[2] * ((j * omega) ** p[3]))))
    return term1 * coth(term2)


def iter_python_csvs(root_folder):
    """Yield Python-ready EIS CSV files below an SOC root.

    Parameters
    ----------
    root_folder : str
        Path to the folder that contains `*SOC` subfolders.

    Yields
    ------
    tuple[str, str]
        SOC subfolder path and matching `_Python.csv` file path.
    """
    for subfolder in glob.glob(os.path.join(root_folder, '*SOC')):
        for csv_file in glob.glob(os.path.join(subfolder, '*_Python.csv')):
            yield subfolder, csv_file


def load_impedance(csv_file, cutoff_frequency=None):
    """Read an EIS CSV and apply the common preprocessing.

    Parameters
    ----------
    csv_file : str
        Python-ready EIS input file.
    cutoff_frequency : float or None
        Minimum frequency to keep, in Hz.

    Returns
    -------
    tuple[numpy.ndarray, numpy.ndarray]
        Frequency values and complex impedance values.
    """
    frequencies, impedance = preprocessing.readCSV(csv_file)
    frequencies, impedance = preprocessing.ignoreBelowX(frequencies, impedance)

    if cutoff_frequency is not None:
        mask = frequencies >= cutoff_frequency
        frequencies = frequencies[mask]
        impedance = impedance[mask]

    return frequencies, impedance


def fit_impedance(frequencies, impedance, config):
    """Fit the configured equivalent circuit.

    Parameters
    ----------
    frequencies : numpy.ndarray
        Frequency values used for fitting.
    impedance : numpy.ndarray
        Measured complex impedance.
    config : FitConfig
        Model and fitting settings.

    Returns
    -------
    tuple[numpy.ndarray, numpy.ndarray, numpy.ndarray]
        Fitted impedance, fitted parameter values, and parameter errors.
    """
    if config.fit_method == "custom_circuit":
        circuit_model = CustomCircuit(initial_guess=config.initial_guess, circuit=config.circuit)
        if config.bounds is None:
            circuit_model.fit(frequencies, impedance, global_opt=True)
        else:
            circuit_model.fit(frequencies, impedance, bounds=config.bounds, global_opt=True)
        return (
            circuit_model.predict(frequencies),
            circuit_model.parameters_,
            circuit_model.p_errors,
        )

    if config.bounds is None:
        p_values, p_errors = circuit_fit(
            frequencies,
            impedance,
            config.circuit,
            config.initial_guess,
            global_opt=True,
        )
    else:
        p_values, p_errors = circuit_fit(
            frequencies,
            impedance,
            config.circuit,
            config.initial_guess,
            bounds=config.bounds,
            global_opt=True,
        )

    circuit_model = CustomCircuit(initial_guess=config.initial_guess, circuit=config.circuit)
    circuit_model.parameters_ = p_values
    return circuit_model.predict(frequencies), p_values, p_errors


def write_fit_outputs(
    subfolder,
    csv_file,
    frequencies,
    impedance,
    fitted_impedance,
    fitted_params,
    parameter_errors,
    config,
):
    """Write fit curve, residuals, RMSE, and parameter CSV files.

    Parameters
    ----------
    subfolder : str
        SOC folder that receives the generated output files.
    csv_file : str
        Source `_Python.csv` file.
    frequencies : numpy.ndarray
        Frequency values used for the fit.
    impedance : numpy.ndarray
        Measured complex impedance.
    fitted_impedance : numpy.ndarray
        Fitted complex impedance.
    fitted_params : numpy.ndarray
        Fitted circuit parameter values.
    parameter_errors : numpy.ndarray
        Estimated parameter errors from the circuit fit.
    config : FitConfig
        Model and output settings.

    Returns
    -------
    tuple[str, numpy.ndarray, numpy.ndarray]
        Output filename base, real residuals, and imaginary residuals.
    """
    output_filename_base = os.path.basename(csv_file).replace('_Python.csv', '_Fit')
    output_csv_path = os.path.join(subfolder, output_filename_base + '.csv')
    saveCSV(output_csv_path, frequencies, fitted_impedance)

    res_meas_real = np.sqrt((impedance - fitted_impedance).real ** 2)
    res_meas_imag = np.sqrt((impedance - fitted_impedance).imag ** 2)

    error_df = pd.DataFrame({
        'Frequency': frequencies,
        'Real_Error': res_meas_real,
        'Imag_Error': res_meas_imag
    })
    error_csv_path = os.path.join(subfolder, output_filename_base + '_errors.csv')
    error_df.to_csv(error_csv_path, index=False)

    rmse_value = rmse(impedance, fitted_impedance)
    rmse_df = pd.DataFrame({'RMSE': [rmse_value]})
    rmse_csv_path = os.path.join(subfolder, output_filename_base + '_rmse.csv')
    rmse_df.to_csv(rmse_csv_path, index=False)

    param_data = {
        'Parameter': config.parameter_names,
        'Value': fitted_params,
    }
    if config.include_parameter_errors:
        param_data['Error'] = parameter_errors

    param_df = pd.DataFrame(param_data)
    param_csv_path = os.path.join(subfolder, output_filename_base + '_params.csv')
    param_df.to_csv(param_csv_path, index=False)

    print(f"Fitted parameters for {csv_file}:", fitted_params)
    print(f"Parameter errors for {csv_file}:", parameter_errors)
    print(f"Errors saved to {error_csv_path}")
    print(f"RMSE for {csv_file}:", rmse_value)
    print(f"RMSE value saved to {rmse_csv_path}")
    print(f"Fitted parameters saved to {param_csv_path}")

    return output_filename_base, res_meas_real, res_meas_imag


def write_lin_kk_outputs(subfolder, output_filename_base, frequencies, impedance, csv_file):
    """Run Lin-KK validation and write its summary files.

    Parameters
    ----------
    subfolder : str
        SOC folder that receives the generated output files.
    output_filename_base : str
        Base name derived from the source CSV file.
    frequencies : numpy.ndarray
        Frequency values used for the fit.
    impedance : numpy.ndarray
        Measured complex impedance.
    csv_file : str
        Source `_Python.csv` file, used only for progress output.
    """
    M, mu, _, res_real, res_imag = linKK(
        frequencies,
        impedance,
        c=0.5,
        max_M=100,
        fit_type='complex',
        add_cap=True,
    )
    print(f'\nCompleted Lin-KK Fit for {csv_file}\nM = {M}\nmu = {mu:.2f}')

    mu_df = pd.DataFrame({'chi_squared': [mu]})
    mu_csv_path = os.path.join(subfolder, output_filename_base + '_mu.csv')
    mu_df.to_csv(mu_csv_path, index=False)

    chi_squared = np.sum((res_real**2 + res_imag**2))
    results_df = pd.DataFrame({
        'chi_squared': [chi_squared],
        'mu': [mu],
        'M': [M]
    })
    kk_results_csv_path = os.path.join(subfolder, output_filename_base + '_kkResults.csv')
    results_df.to_csv(kk_results_csv_path, index=False)
    print(f"Results saved to {kk_results_csv_path}")


def show_diagnostic_plot(impedance, fitted_impedance, frequencies, residual_real, residual_imag):
    """Show the Nyquist fit and residuals for one fitted file.

    Parameters
    ----------
    impedance : numpy.ndarray
        Measured complex impedance.
    fitted_impedance : numpy.ndarray
        Fitted complex impedance.
    frequencies : numpy.ndarray
        Frequency values used for the fit.
    residual_real : numpy.ndarray
        Real part residuals.
    residual_imag : numpy.ndarray
        Imaginary part residuals.
    """
    fig, ax = plt.subplots(figsize=(10, 10))
    gs = fig.add_gridspec(3, 1)
    ax1 = fig.add_subplot(gs[:2, :])
    ax2 = fig.add_subplot(gs[2, :])

    plot_nyquist(impedance, fmt='o', ax=ax1)
    plot_nyquist(fitted_impedance, fmt='-', ax=ax1)

    ax1.legend(['Data', 'Fit'], loc=2, fontsize=12)
    ax1.set_title('Nyquist Plot')

    plot_residuals(
        ax2,
        frequencies,
        residual_real,
        residual_imag,
        y_limits=(-2, 2),
    )

    plt.tight_layout()
    plt.show()


def process_file(subfolder, csv_file, config):
    """Fit one `_Python.csv` file and write all generated outputs.

    Parameters
    ----------
    subfolder : str
        SOC folder that contains the source file.
    csv_file : str
        Python-ready EIS input file.
    config : FitConfig
        Model and output settings.
    """
    frequencies, impedance = load_impedance(csv_file, config.cutoff_frequency)
    fitted_impedance, fitted_params, parameter_errors = fit_impedance(
        frequencies,
        impedance,
        config,
    )

    output_filename_base, residual_real, residual_imag = write_fit_outputs(
        subfolder,
        csv_file,
        frequencies,
        impedance,
        fitted_impedance,
        fitted_params,
        parameter_errors,
        config,
    )
    write_lin_kk_outputs(subfolder, output_filename_base, frequencies, impedance, csv_file)

    if config.show_plot:
        show_diagnostic_plot(
            impedance,
            fitted_impedance,
            frequencies,
            residual_real,
            residual_imag,
        )


def run_soc_folder(root_folder, config):
    """Fit all Python-ready EIS files in an SOC folder.

    Parameters
    ----------
    root_folder : str
        Path to the folder that contains `*SOC` subfolders.
    config : FitConfig
        Model and output settings.
    """
    for subfolder, csv_file in iter_python_csvs(root_folder):
        try:
            process_file(subfolder, csv_file, config)
        except Exception as e:
            print(f"An error occurred during the fitting process for {csv_file}:", e)
