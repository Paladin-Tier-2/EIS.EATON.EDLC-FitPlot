import os
import glob
import pandas as pd
import numpy as np

# Define the path to the root folder
root_folder_path = 'C:/Users/DankyATM/Downloads/1F/'

# List to store all the data
all_data = []

# Loop through each subfolder in the root folder
for subfolder in glob.glob(os.path.join(root_folder_path, '*SOC')):
    soc_name = os.path.basename(subfolder)
    
    # Read KK results CSV
    kk_results_file = glob.glob(os.path.join(subfolder, '*_kkResults.csv'))
    if kk_results_file:
        kk_results_df = pd.read_csv(kk_results_file[0])
        kk_results_df['SOC'] = soc_name
    
    # Read RMSE CSV
    rmse_file = glob.glob(os.path.join(subfolder, '*_rmse.csv'))
    if rmse_file:
        rmse_df = pd.read_csv(rmse_file[0])
        rmse_df['SOC'] = soc_name
    
    # Merge KK results and RMSE data
    if kk_results_file and rmse_file:
        combined_df = pd.merge(kk_results_df, rmse_df, on='SOC')
        all_data.append(combined_df)
    elif kk_results_file:
        kk_results_df['RMSE'] = None
        all_data.append(kk_results_df)
    elif rmse_file:
        rmse_df['chi_squared'] = None
        rmse_df['mu'] = None
        rmse_df['M'] = None
        all_data.append(rmse_df)

# Combine all the data into a single DataFrame
final_df = pd.concat(all_data, ignore_index=True)

# Sort the DataFrame by SOC in descending order
final_df = final_df.sort_values(by='SOC', key=lambda x: x.str.extract(r'(\d+)')[0].astype(int), ascending=False)

# Remove 'SOC' from the SOC names and format them as percentages
final_df['SOC'] = final_df['SOC'].str.extract(r'(\d+)')[0] + r'\%'


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

# Apply scientific notation formatting
final_df['RMSE'] = final_df['RMSE'].apply(lambda x: sci_notation(x, decimal_digits=3))
final_df['chi_squared'] = final_df['chi_squared'].apply(lambda x: sci_notation(x, decimal_digits=6))

# Separate the DataFrame for the two tables
rmse_df = final_df[['SOC', 'RMSE']]
fit_results_df = final_df[['SOC', 'M', 'mu', 'chi_squared']]

# LaTeX code template for the tables
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

# Generate the table rows
rmse_rows = "\n".join([f"{row['SOC']} & {row['RMSE']} \\\\" for _, row in rmse_df.iterrows()])
fit_rows = "\n".join([f"{row['SOC']} & {row['M']} & {row['mu']} & {row['chi_squared']} \\\\" for _, row in fit_results_df.iterrows()])


# Fill in the template
latex_code = latex_template % (rmse_rows, fit_rows)

# Define the path to the output .tex file
output_path = os.path.join(root_folder_path, 'tables.tex')

# Write the LaTeX code to the .tex file
with open(output_path, 'w') as f:
    f.write(latex_code)

print(f"LaTeX table saved to {output_path}")
