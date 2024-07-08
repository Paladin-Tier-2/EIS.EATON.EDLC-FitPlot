import os
import glob
import pandas as pd
import numpy as np

# Define the path to the root folder
root_folder_path = 'C:/Users/DankyATM/Downloads/1F/'

# Parameters of interest --- it looks for this
parameters = ['R_s', 'Wo_Zo',  'Wo_T', 'CPE_H', 'alpha_H','R_int','CPE_ads','alpha_ads']

# Function to format numbers in scientific notation for LaTeX
def sci_notation(num, decimal_digits=1, precision=None, exponent=None):
    if num == 0:
        return "0"
    if exponent is None:
        exponent = int(np.floor(np.log10(abs(num))))
    coeff = round(num / float(10**exponent), decimal_digits)
    if precision is None:
        precision = decimal_digits
    return f"${coeff:.{precision}f} \\times 10^{{{exponent}}}$"

# Function to process fit_params.csv files and gather data
def process_fit_params(subfolder):
    # Read the fit_params.csv file
    fit_params_file = glob.glob(os.path.join(subfolder, '*_Fit_params.csv'))
    if fit_params_file:
        fit_params_df = pd.read_csv(fit_params_file[0])
        
        # Ensure 'Value' column is of type string
        fit_params_df['Value'] = fit_params_df['Value'].astype(str)

        # Extract SOC name from the folder name and handle exception if it cannot be converted
        soc_name = os.path.basename(subfolder).replace('F', '').replace('SOC', '').replace('%', '')
        try:
            soc_value = int(soc_name)
        except ValueError:
            soc_value = 0

        # Filter only the parameters of interest
        fit_params_df = fit_params_df[fit_params_df['Parameter'].isin(parameters)]

        # Check for non-empty 'Value' before applying scientific notation
        for param in parameters:
            if param in fit_params_df['Parameter'].values:
                fit_params_df.loc[fit_params_df['Parameter'] == param, 'Value'] = fit_params_df.loc[fit_params_df['Parameter'] == param, 'Value'].apply(lambda x: sci_notation(float(x), decimal_digits=3) if x else '')

        # Handle the creation of soc_dict carefully to avoid missing 'Value' entries
        soc_dict = {'SOC': f"{soc_value}\\%"}
        for param in parameters:
            value = fit_params_df.loc[fit_params_df['Parameter'] == param, 'Value']
            soc_dict[param] = value.values[0] if not value.empty else ''

        return soc_value, soc_dict
    
    print(f"No fit_params.csv file found in {subfolder}")
    return None, None

# Process each SOC subfolder and gather data
soc_data = []
for subfolder in glob.glob(os.path.join(root_folder_path, '*SOC')):
    soc_value, soc_dict = process_fit_params(subfolder)
    if soc_dict is not None:
        soc_data.append((soc_value, soc_dict))

# Check if any data was collected
if not soc_data:
    print("No SOC data found.")
else:
    # Sort data by SOC values in descending order
    soc_data.sort(reverse=True, key=lambda x: x[0])

    # Create LaTeX table
    latex_table = r"""
\begin{table*}[!htb]
\centering
\begin{tabular}{l|cccccccc}
\toprule
\textbf{SOC} & $R_s$[\SI{}{\ohm}] & $Z_0$ [\SI{}{\ohm}] & $ \tau $[\SI{}{\second}] & $CPE_1_0$ [$\frac{s^{\alpha}}{\SI{}{\ohm}}$] & $CPE_1_1$ & $R_2$[\SI{}{\ohm}] & $CPE_2_0$ [$\frac{s^{\alpha}}{\SI{}{\ohm}}$] & $CPE_2_1$ \\
\midrule
"""
    for _, soc_dict in soc_data:
        row = f"{soc_dict['SOC']} & " + " & ".join(soc_dict.get(param, '') for param in parameters) + r" \\" + "  \n "
        latex_table += row
    latex_table += r"""
\bottomrule
\end{tabular}
\caption{}
\label{}
\end{table*}
"""

    # Define the path to the output .tex file
    output_path = os.path.join(root_folder_path, 'fit_params_combined_table.tex')

    # Write the LaTeX code to the .tex file
    with open(output_path, 'w') as f:
        f.write(latex_table)

    print(f"LaTeX table saved to {output_path}")
