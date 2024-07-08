import pandas as pd
import numpy as np
import matplotlib.pyplot as plt
from impedance.models.circuits import CustomCircuit
from impedance.models.circuits.elements import element
from impedance.visualization import plot_nyquist, plot_residuals
from impedance import preprocessing
from impedance.preprocessing import saveCSV
from impedance.models.circuits.fitting import circuit_fit, rmse
from impedance.validation import linKK,get_tc_distribution

# Define the path to the subfolder
subfolder_path = 'C:/Users/DankyATM/Downloads/1F/SingleTest-Vertification/'

# Load data from the example EIS data
frequencies, Z = preprocessing.readCSV('C:/Users/DankyATM/Downloads/1F/80%SOC/1F-80%SOC_Python.csv')

# Ignore Below X-axis 
frequencies, Z = preprocessing.ignoreBelowX(frequencies, Z)

# Define the cutoff frequency
cutoff_frequency = 100e-3  # in Hz

# Apply cutoff frequency
mask = frequencies >= cutoff_frequency
frequencies = frequencies[mask]
Z = Z[mask]


circuit = 'R_1-Wo_1-p(CPE_1,R_2-CPE_2)'

initial_guess = [5.51731416e-02, 2.62415249e-01, 2.86877603e-01, 4.03352192e-04, 9.99239049e-01, 3.99821566e-02, 2.17717863e+01, 4.19073668e-01]


# Fit the circuit model using basinhopping for global optimization
try:

    p_values, p_errors = circuit_fit(frequencies, Z, circuit, initial_guess,global_opt=True)
    
    # Create the CustomCircuit with fitted parameters
    circuit_model = CustomCircuit(initial_guess=initial_guess, circuit=circuit)
    circuit_model.parameters_ = p_values

    # Predict impedance using the fitted circuit model
    Z_fit = circuit_model.predict(frequencies)

    # Get the fitted parameters
    fitted_params = circuit_model.parameters_
    print("Fitted parameters:", fitted_params)
    print("Parameter errors:", p_errors)

    # Save the fitted data to a CSV file in the specified subfolder
    saveCSV(subfolder_path + 'fitted_dataBasic.csv', frequencies, Z_fit)

    # Calculate residuals
    res_meas_real = np.sqrt((Z - Z_fit).real ** 2)
    res_meas_imag = np.sqrt((Z - Z_fit).imag ** 2)

    # Create a DataFrame to save the errors along with the frequencies
    error_df = pd.DataFrame({
        'Frequency': frequencies,
        'Real_Error': res_meas_real,
        'Imag_Error': res_meas_imag
    })

    # Save the error data to a CSV file in the specified subfolder
    error_df.to_csv(subfolder_path + 'impedance_fit_errorsBasic.csv', index=False)
    print("Errors saved to impedance_fit_errorsBasic.csv")

    # Calculate RMSE between the fit and the data
    rmse_value = rmse(Z, Z_fit)
    print("RMSE:", rmse_value)

    # Save the RMSE value to a CSV file
    rmse_df = pd.DataFrame({'RMSE': [rmse_value]})
    rmse_df.to_csv(subfolder_path + 'rmse_valueBasic.csv', index=False)
    print("RMSE value saved to rmse_valueBasic.csv")

    # Perform the lin-KK test
    M, mu, Z_linKK, res_real, res_imag = linKK(frequencies, Z, c=0.5, max_M=100, fit_type='complex', add_cap=True)
    print('\nCompleted Lin-KK Fit\nM = {:d}\nmu = {:.2f}'.format(M, mu))

    tc_distribution = get_tc_distribution(frequencies,M)
    # Save the time-constant distribution to a CSV file
    tc_df = pd.DataFrame({'Time_Constant': tc_distribution})
    tc_df.to_csv(subfolder_path + 'tc_distributionNormal.csv', index=False)
    print("Time-constant distribution saved to tc_distribution.csv")


    # Calculate chi-squared value using the formula provided in the documentation
    chi_squared = np.sum((res_real**2 + res_imag**2))

    # Create a DataFrame to save the chi-squared value, mu, M, and the lin-KK results
    KKresults_df = pd.DataFrame({
        'Frequency': frequencies,
        'Z_real': Z.real,
        'Z_imag': Z.imag,
        'Z_linKK_real': Z_linKK.real,
        'Z_linKK_imag': Z_linKK.imag,
        'res_real': res_real,
        'res_imag': res_imag,
        'chi_squared': [chi_squared] * len(frequencies),
        'mu': [mu] * len(frequencies),
        'M': [M] * len(frequencies)
    })

    # Save the results to a CSV file
    KKresults_df.to_csv(subfolder_path + 'kkResultsBasic.csv', index=False)
    print("Results saved to kkResults.csv")


    # Plotting the Nyquist plot with a larger figure size
    fig, ax = plt.subplots(figsize=(10, 10))
    gs = fig.add_gridspec(3, 1)
    ax1 = fig.add_subplot(gs[:2, :])
    ax2 = fig.add_subplot(gs[2, :])

    # Plot original data
    plot_nyquist(Z, fmt='o', ax=ax1)
    plot_nyquist(Z_fit, fmt='-', ax=ax1)

    ax1.legend(['Data', 'Fit'], loc=2, fontsize=12)
    ax1.set_title('Nyquist Plot')

    # Plot residuals
    plot_residuals(ax2, frequencies, res_meas_real, res_meas_imag, y_limits=(-2, 2))

    plt.tight_layout()
    plt.show()

    # Plotting the lin-KK test results in a separate window
    fig_kk, ax_kk = plt.subplots(figsize=(10, 10))
    gs_kk = fig_kk.add_gridspec(3, 1)
    ax1_kk = fig_kk.add_subplot(gs_kk[:2, :])
    ax2_kk = fig_kk.add_subplot(gs_kk[2, :])

    # Plot original data and lin-KK fit
    plot_nyquist(Z, fmt='o', ax=ax1_kk)
    plot_nyquist(Z_linKK, fmt='-', ax=ax1_kk)

    ax1_kk.legend(['Data', 'Lin-KK'], loc=2, fontsize=12)
    ax1_kk.set_title('Nyquist Plot - Lin-KK Test')

    # Plot lin-KK residuals
    plot_residuals(ax2_kk, frequencies, res_real, res_imag, y_limits=(-2, 2))

    plt.tight_layout()
    plt.show()


except Exception as e:
    print("An error occurred during the fitting process:", e)
