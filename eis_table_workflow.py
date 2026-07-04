"""Shared LaTeX table builders for generated EIS fit outputs."""

import glob
import os

import numpy as np
import pandas as pd


BISQUERT_PARAMETERS = ['R_0', 'B_1_0', 'B_1_1', 'B_1_2', 'B_1_3', 'B_1_4']
DISTINCT_PARAMETERS = [
    'R_s',
    'Wo_Zo',
    'Wo_T',
    'CPE_H',
    'alpha_H',
    'R_int',
    'CPE_ads',
    'alpha_ads',
]

BISQUERT_TABLE_HEADER = r"""
\begin{table*}[!htb]
\centering
\begin{tabular}{l|cccccc}
\toprule
\textbf{SOC} & $R_0$[\SI{}{\ohm}] & $R_m$ [\SI{}{\ohm}] & $R_k$[\SI{}{\ohm}] & $Q$ [$\frac{s^{\alpha}}{\SI{}{\ohm}}$] & $\alpha$ & $L$ [\SI{}{\meter}] \\
\midrule
"""

DISTINCT_TABLE_HEADER = r"""
\begin{table*}[!htb]
\centering
\begin{tabular}{l|cccccccc}
\toprule
\textbf{SOC} & $R_s$[\SI{}{\ohm}] & $Z_0$ [\SI{}{\ohm}] & $ \tau $[\SI{}{\second}] & $CPE_1_0$ [$\frac{s^{\alpha}}{\SI{}{\ohm}}$] & $CPE_1_1$ & $R_2$[\SI{}{\ohm}] & $CPE_2_0$ [$\frac{s^{\alpha}}{\SI{}{\ohm}}$] & $CPE_2_1$ \\
\midrule
"""

TABLE_FOOTER = r"""
\bottomrule
\end{tabular}
\caption{}
\label{}
\end{table*}
"""


def sci_notation(num, decimal_digits=1, precision=None, exponent=None):
    """Format a number as LaTeX scientific notation.

    Parameters
    ----------
    num : float
        Number to format.
    decimal_digits : int
        Number of digits after the decimal point.
    precision : int or None
        Display precision. Defaults to `decimal_digits`.
    exponent : int or None
        Fixed exponent. If omitted, the exponent is inferred from `num`.

    Returns
    -------
    str
        LaTeX scientific-notation string.
    """
    if num == 0:
        return "0"
    if exponent is None:
        exponent = int(np.floor(np.log10(abs(num))))
    coeff = round(num / float(10**exponent), decimal_digits)
    if precision is None:
        precision = decimal_digits
    return f"${coeff:.{precision}f} \\times 10^{{{exponent}}}$"


def soc_value_from_folder(subfolder):
    """Extract the SOC percentage from an SOC folder path.

    Parameters
    ----------
    subfolder : str
        Folder name or path such as `40%SOC`.

    Returns
    -------
    int
        SOC value. Returns 0 if the folder name cannot be parsed.
    """
    soc_name = os.path.basename(subfolder).replace('F', '').replace('SOC', '').replace('%', '')
    try:
        return int(soc_name)
    except ValueError:
        return 0


def write_fit_quality_tables(root_folder):
    """Write LaTeX RMSE and Lin-KK summary tables.

    Parameters
    ----------
    root_folder : str or pathlib.Path
        SOC folder that contains `*SOC` subfolders.
    """
    all_data = []

    for subfolder in glob.glob(os.path.join(root_folder, '*SOC')):
        soc_name = os.path.basename(subfolder)

        kk_results_file = glob.glob(os.path.join(subfolder, '*_kkResults.csv'))
        if kk_results_file:
            kk_results_df = pd.read_csv(kk_results_file[0])
            kk_results_df['SOC'] = soc_name

        rmse_file = glob.glob(os.path.join(subfolder, '*_rmse.csv'))
        if rmse_file:
            rmse_df = pd.read_csv(rmse_file[0])
            rmse_df['SOC'] = soc_name

        if kk_results_file and rmse_file:
            all_data.append(pd.merge(kk_results_df, rmse_df, on='SOC'))
        elif kk_results_file:
            kk_results_df['RMSE'] = None
            all_data.append(kk_results_df)
        elif rmse_file:
            rmse_df['chi_squared'] = None
            rmse_df['mu'] = None
            rmse_df['M'] = None
            all_data.append(rmse_df)

    final_df = pd.concat(all_data, ignore_index=True)
    final_df = final_df.sort_values(
        by='SOC',
        key=lambda x: x.str.extract(r'(\d+)')[0].astype(int),
        ascending=False,
    )
    final_df['SOC'] = final_df['SOC'].str.extract(r'(\d+)')[0] + r'\%'
    final_df['RMSE'] = final_df['RMSE'].apply(lambda x: sci_notation(x, decimal_digits=3))
    final_df['chi_squared'] = final_df['chi_squared'].apply(
        lambda x: sci_notation(x, decimal_digits=6)
    )

    rmse_df = final_df[['SOC', 'RMSE']]
    fit_results_df = final_df[['SOC', 'M', 'mu', 'chi_squared']]

    latex_template = r"""
\begin{table}[h!]
\centering
\caption{}
\begin{tabular}{|c|c|}
\hline
\textbf{SOC} & \textbf{RMSE}[\SI{}{\ohm}] \\
\hline
%s
\hline
\end{tabular}
\end{table}

\begin{table}[h!]
\centering
\caption{}
\begin{tabular}{|c|c|c|c|}
\hline
SOC & M & $\mu$ & $\chi^2$ \\
\hline
%s
\hline
\end{tabular}
\end{table}
"""
    rmse_rows = "\n".join(
        [f"{row['SOC']} & {row['RMSE']} \\\\" for _, row in rmse_df.iterrows()]
    )
    fit_rows = "\n".join(
        [
            f"{row['SOC']} & {row['M']} & {row['mu']} & {row['chi_squared']} \\\\"
            for _, row in fit_results_df.iterrows()
        ]
    )

    output_path = os.path.join(root_folder, 'tables.tex')
    with open(output_path, 'w') as f:
        f.write(latex_template % (rmse_rows, fit_rows))

    print(f"LaTeX table saved to {output_path}")


def collect_fit_params(subfolder, parameters):
    """Read selected fit parameters from one SOC folder.

    Parameters
    ----------
    subfolder : str
        SOC folder that contains a `_Fit_params.csv` file.
    parameters : list[str]
        Parameter names to include in the output table.

    Returns
    -------
    tuple[int, dict] or tuple[None, None]
        SOC value and table row dictionary. Returns `(None, None)` if no fit
        parameter file is found.
    """
    fit_params_file = glob.glob(os.path.join(subfolder, '*_Fit_params.csv'))
    if not fit_params_file:
        print(f"No fit_params.csv file found in {subfolder}")
        return None, None

    fit_params_df = pd.read_csv(fit_params_file[0])
    fit_params_df['Value'] = fit_params_df['Value'].astype(str)

    soc_value = soc_value_from_folder(subfolder)
    fit_params_df = fit_params_df[fit_params_df['Parameter'].isin(parameters)]

    for param in parameters:
        if param in fit_params_df['Parameter'].values:
            fit_params_df.loc[fit_params_df['Parameter'] == param, 'Value'] = (
                fit_params_df.loc[fit_params_df['Parameter'] == param, 'Value']
                .apply(lambda x: sci_notation(float(x), decimal_digits=3) if x else '')
            )

    soc_dict = {'SOC': f"{soc_value}\\%"}
    for param in parameters:
        value = fit_params_df.loc[fit_params_df['Parameter'] == param, 'Value']
        soc_dict[param] = value.values[0] if not value.empty else ''

    return soc_value, soc_dict


def write_param_table(root_folder, parameters, table_header):
    """Write one combined LaTeX parameter table.

    Parameters
    ----------
    root_folder : str or pathlib.Path
        SOC folder that contains `*SOC` subfolders.
    parameters : list[str]
        Parameter names to include in the table.
    table_header : str
        LaTeX table header for the selected model.
    """
    soc_data = []
    for subfolder in glob.glob(os.path.join(root_folder, '*SOC')):
        soc_value, soc_dict = collect_fit_params(subfolder, parameters)
        if soc_dict is not None:
            soc_data.append((soc_value, soc_dict))

    if not soc_data:
        print("No SOC data found.")
        return

    soc_data.sort(reverse=True, key=lambda x: x[0])

    latex_table = table_header
    for _, soc_dict in soc_data:
        row = f"{soc_dict['SOC']} & "
        row += " & ".join(soc_dict.get(param, '') for param in parameters)
        row += r" \\" + "  \n "
        latex_table += row
    latex_table += TABLE_FOOTER

    output_path = os.path.join(root_folder, 'fit_params_combined_table.tex')
    with open(output_path, 'w') as f:
        f.write(latex_table)

    print(f"LaTeX table saved to {output_path}")


def write_bisquert_param_table(root_folder):
    """Write the Bisquert fit-parameter LaTeX table.

    Parameters
    ----------
    root_folder : str or pathlib.Path
        SOC folder that contains `*SOC` subfolders.
    """
    write_param_table(root_folder, BISQUERT_PARAMETERS, BISQUERT_TABLE_HEADER)


def write_distinct_param_table(root_folder):
    """Write the distinct-model fit-parameter LaTeX table.

    Parameters
    ----------
    root_folder : str or pathlib.Path
        SOC folder that contains `*SOC` subfolders.
    """
    write_param_table(root_folder, DISTINCT_PARAMETERS, DISTINCT_TABLE_HEADER)
