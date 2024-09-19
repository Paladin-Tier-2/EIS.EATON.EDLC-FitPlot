import os
import glob
import pandas as pd
import numpy as np
import matplotlib.pyplot as plt
from impedance.models.circuits import CustomCircuit
from impedance.models.circuits.elements import element
from impedance.visualization import plot_nyquist, plot_residuals
from impedance import preprocessing
from impedance.preprocessing import saveCSV
from impedance.models.circuits.fitting import circuit_fit, rmse
from impedance.validation import linKK

circuit = 'R_1-Wo_1-p(CPE_1,R_2-CPE_2)'

initial_guess = [5.51731416e-02, 2.62415249e-01, 2.86877603e-01, 4.03352192e-04, 9.99239049e-01, 3.99821566e-02, 2.17717863e+01, 4.19073668e-01]
bounds = ([1e-2,0, 0, 0, 0.5, 0,1e-1,0.5], [10e-2,np.inf,np.inf, 10 ,1 ,0.1 ,1e3 ,1 ])

# Define the cutoff frequency
cutoff_frequency = 100e-3  # in Hz

# Define the path to the root folder --- change it hereee
root_folder_path = os.path.dirname(os.path.realpath(__file__))

# Loop through each subfolder in the root folder
for subfolder in glob.glob(os.path.join(root_folder_path, '*SOC')):
    # Find the CSV files in the current subfolder
    csv_files = glob.glob(os.path.join(subfolder, '*_Python.csv'))

    for csv_file in csv_files:
        # Load data from the CSV file
        frequencies, Z = preprocessing.readCSV(csv_file)
        
        # Ignore below X-axis
        frequencies, Z = preprocessing.ignoreBelowX(frequencies, Z)

        # Apply cutoff frequency
        mask = frequencies >= cutoff_frequency
        frequencies = frequencies[mask]
        Z = Z[mask]
        
        # Fit the circuit model using basinhopping for global optimization
        try:
            p_values, p_errors = circuit_fit(frequencies, Z, circuit, initial_guess,bounds=bounds,global_opt=True)
            
            # Create the CustomCircuit with fitted parameters
            circuit_model = CustomCircuit(initial_guess=initial_guess, circuit=circuit)
            circuit_model.parameters_ = p_values

            # Predict impedance using the fitted circuit model
            Z_fit = circuit_model.predict(frequencies)

            # Get the fitted parameters
            fitted_params = circuit_model.parameters_
            print(f"Fitted parameters for {csv_file}:", fitted_params)
            print(f"Parameter errors for {csv_file}:", p_errors)

            # Derive the output filenames from the input CSV filenames
            output_filename_base = os.path.basename(csv_file).replace('_Python.csv', '_Fit')
            output_csv_path = os.path.join(subfolder, output_filename_base + '.csv')

            # Save the fitted data to a CSV file
            saveCSV(output_csv_path, frequencies, Z_fit)

            # Calculate residuals
            res_meas_real = np.sqrt((Z - Z_fit).real ** 2)
            res_meas_imag = np.sqrt((Z - Z_fit).imag ** 2)

            # Create a DataFrame to save the errors along with the frequencies
            error_df = pd.DataFrame({
                'Frequency': frequencies,
                'Real_Error': res_meas_real,
                'Imag_Error': res_meas_imag
            })

            # Save the error data to a CSV file
            error_csv_path = os.path.join(subfolder, output_filename_base + '_errors.csv')
            error_df.to_csv(error_csv_path, index=False)
            print(f"Errors saved to {error_csv_path}")

            # Calculate RMSE between the fit and the data
            rmse_value = rmse(Z, Z_fit)
            print(f"RMSE for {csv_file}:", rmse_value)

            # Save the RMSE value to a CSV file
            rmse_df = pd.DataFrame({'RMSE': [rmse_value]})
            rmse_csv_path = os.path.join(subfolder, output_filename_base + '_rmse.csv')
            rmse_df.to_csv(rmse_csv_path, index=False)
            print(f"RMSE value saved to {rmse_csv_path}")

            # Save the fitted parameters to a CSV file
            param_df = pd.DataFrame({
                'Parameter': ['R_s', 'Wo_Zo',  'Wo_T', 'CPE_H', 'alpha_H','R_int','CPE_ads','alpha_ads'],
                'Value': fitted_params    
            })

            param_csv_path = os.path.join(subfolder, output_filename_base + '_params.csv')
            param_df.to_csv(param_csv_path, index=False)
            print(f"Fitted parameters saved to {param_csv_path}")

            # Perform the lin-KK test
            M, mu, Z_linKK, res_real, res_imag = linKK(frequencies, Z, c=0.5, max_M=100, fit_type='complex', add_cap=True)
            print(f'\nCompleted Lin-KK Fit for {csv_file}\nM = {M}\nmu = {mu:.2f}')
            mu_df = pd.DataFrame({'chi_squared': [mu]})
            mu_csv_path = os.path.join(subfolder, output_filename_base + '_mu.csv')
            mu_df.to_csv(mu_csv_path, index=False)
            
            # Calculate chi-squared value
            chi_squared = np.sum((res_real**2 + res_imag**2))

            # Create a DataFrame to save the chi-squared value, mu, and M
            results_df = pd.DataFrame({
                'chi_squared': [chi_squared],
                'mu': [mu],
                'M': [M]
            })

            # Save the results to a CSV file
            kk_results_csv_path = os.path.join(subfolder, output_filename_base + '_kkResults.csv')
            results_df.to_csv(kk_results_csv_path, index=False)
            print(f"Results saved to {kk_results_csv_path}")

            # Plotting the Nyquist plot with a larger figure size
            ## Don't plot if you want everything at one go
            #fig, ax = plt.subplots(figsize=(10, 10))
            #gs = fig.add_gridspec(3, 1)
            #ax1 = fig.add_subplot(gs[:2, :])
            #ax2 = fig.add_subplot(gs[2, :])

            # Plot original data
            #plot_nyquist(Z, fmt='o', ax=ax1)
            #plot_nyquist(Z_fit, fmt='-', ax=ax1)

           # ax1.legend(['Data', 'Fit'], loc=2, fontsize=12)
            #ax1.set_title('Nyquist Plot')

            # Plot residuals
            #plot_residuals(ax2, frequencies, res_meas_real, res_meas_imag, y_limits=(-2, 2))

           # plt.tight_layout()
            #plt.show()

        except Exception as e:
            print(f"An error occurred during the fitting process for {csv_file}:", e)



             
