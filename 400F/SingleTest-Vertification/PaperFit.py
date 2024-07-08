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



# Define the path to the subfolder
subfolder_path = 'C:/Users/DankyATM/Downloads/400F/SingleTest-Vertification/'

# Load data from the example EIS data
frequencies, Z = preprocessing.readCSV('C:/Users/DankyATM/Downloads/400F/SingleTest-Vertification/400F-80%SOC_Python.csv')

# Ignore Below X-axis 
frequencies, Z = preprocessing.ignoreBelowX(frequencies, Z)

# Define the custom coth function
def coth(x):
    return 1 / np.tanh(x)

# Define the custom Z_BTO function with the @element decorator
@element(10, units=['(s^α)/Ω', '', 'Ohm','S^1.s^1/2','s^1/2', '(s^α)/Ω', '','Ohm','(s^α)/Ω', ''])
def B(p, f):
    j = 1j  # imaginary unit
    omega = 2 * np.pi * np.array(f)
    
    Z_CPE_bulk = 1 / (p[0] * (j * omega)**p[1])
    Z_W =  1/(p[3] * np.sqrt(j*omega)) * coth(p[4] * np.sqrt(j*omega))
    Z_CPE_H = 1 / (p[5] * (j * omega)**p[6])
    Z_CPE_ads = 1 / (p[8] * (j * omega)**p[9])
    Z_total =  ( (1/Z_CPE_bulk) +  1/( (p[2]+Z_W) +  ((1/Z_CPE_H) + (1/(p[7]+Z_CPE_ads)) )**-1 ) )**-1 
    return Z_total


# Define the circuit
circuit = 'R0-B'


initial_guess = [2.4e-3, 1, 0.9, 1000, 1e-2, 1e-4, 400,1, 200, 0.1, 0.7]


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
    saveCSV(subfolder_path + 'fitted_dataPaper.csv', frequencies, Z_fit)

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
    error_df.to_csv(subfolder_path + 'impedance_fit_errorsPaper.csv', index=False)
    print("Errors saved to impedance_fit_errorsPaper.csv")

    # Calculate RMSE between the fit and the data
    rmse_value = rmse(Z, Z_fit)
    print("RMSE:", rmse_value)

    # Save the RMSE value to a CSV file
    rmse_df = pd.DataFrame({'RMSE': [rmse_value]})
    rmse_df.to_csv(subfolder_path + 'rmse_valuePaper.csv', index=False)
    print("RMSE value saved to rmse_valuePaper.csv")


    # Perform the lin-KK test
    M, mu, Z_linKK, res_real, res_imag = linKK(frequencies, Z, c=0.5, max_M=100, fit_type='complex', add_cap=True)
    print('\nCompleted Lin-KK Fit\nM = {:d}\nmu = {:.2f}'.format(M, mu))

 
    # Calculate chi-squared value using the formula provided in the documentation
    chi_squared = np.sum((res_real**2 + res_imag**2))

    # Create a DataFrame to save the chi-squared value, mu, and M
    KKresults_df = pd.DataFrame({
    'chi_squared': [chi_squared],
    'mu': [mu],
    'M': [M]
    })

    # Save the results to a CSV file
    KKresults_df.to_csv(subfolder_path + 'kkResultsPaper.csv', index=False)
    print("Results saved to kkResultsPaper.csv")

    
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
except Exception as e:
    print("An error occurred during the fitting process:", e)



