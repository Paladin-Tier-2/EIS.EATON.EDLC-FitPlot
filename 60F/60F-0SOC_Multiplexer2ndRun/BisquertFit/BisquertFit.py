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
subfolder_path = 'C:/Users/DankyATM/Downloads/60F/60F-0SOC_Multiplexer2ndRun/BisquertFit/'

# Load data from the example EIS data
frequencies, Z = preprocessing.readCSV('C:/Users/DankyATM/Downloads/60F/60F-0SOC_Multiplexer2ndRun/60F-0SOC_Multiplexer2ndRun_0%SOC_AfterMath_Real&Imag.csv')

# Ignore Below X-axis 
frequencies, Z = preprocessing.ignoreBelowX(frequencies, Z)

# Define the custom coth function
def coth(x):
    return 1 / np.tanh(x)

# Define the custom Z_BTO function with the @element decorator
@element(5, units=['Ohm', 'Ohm', '(s^α)/Ω', '', 'm'])
def B(p, f):
    ### p0   p1   p2  p3  p4
    #  r_m, r_k, Q, alpha, L
    j = 1j  # imaginary unit
    omega = 2 * np.pi * np.array(f)
    #term1 = np.sqrt(p[0] / ( (1 / p[1]) + ( p[2] * ( (j * omega) ** p[3] ) ) ))
    term1 = np.sqrt( (p[0] * p[1]) / ( 1 + ( p[2] * p[1] * (j * omega) ** p[3]  ) ))
    #term2 = p[4] * np.sqrt(p[0] * (  (1 / p[1]) + (  p[2] * ((j * omega) ** p[3]) ) ))
    term2 = p[4] * np.sqrt( ( 1 + (  p[1] * p[2] * ((j * omega) ** p[3]) ) )/ p[1] )
    return term1 * coth(term2)

# Define the circuit:
circuit = 'R_0-B_1'

# Initial guesses for parameters excluding the constants
#initial_guess = [7.43197184e-03, 112e-3, 60, 9.62423346e-01]
#initial_guess = [L_0, R_0, R_m, R_k, Q, alpha,L]
initial_guess = [ 7.43197184e-03, 112e-3, 1e32, 60, 9.62423346e-01,1]

# Define constants

#constants = {
# 'B_1_1': 1e32,  # r_k
# 'B_1_4': 1  # L
#}

# Fit the circuit model using basinhopping for global optimization
try:
    #p_values, p_errors = circuit_fit(frequencies, Z, circuit, initial_guess, constants=constants, global_opt=True)
    p_values, p_errors = circuit_fit(frequencies, Z, circuit, initial_guess, global_opt=True)
    
    # Create the CustomCircuit with fitted parameters
    circuit_model = CustomCircuit(initial_guess=initial_guess, circuit=circuit)
   # circuit_model = CustomCircuit(initial_guess=initial_guess, constants=constants, circuit=circuit)
    circuit_model.parameters_ = p_values

    # Predict impedance using the fitted circuit model
    Z_fit = circuit_model.predict(frequencies)

    # Get the fitted parameters
    fitted_params = circuit_model.parameters_
    print("Fitted parameters:", fitted_params)
    print("Parameter errors:", p_errors)

    # Save the fitted data to a CSV file in the specified subfolder
    saveCSV(subfolder_path + 'fitted_dataBisquert.csv', frequencies, Z_fit)

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
    error_df.to_csv(subfolder_path + 'impedance_fit_errorsBisquert.csv', index=False)
    print("Errors saved to impedance_fit_errorsBisquert.csv")

    # Calculate RMSE between the fit and the data
    rmse_value = rmse(Z, Z_fit)
    print("RMSE:", rmse_value)

    # Save the RMSE value to a CSV file
    rmse_df = pd.DataFrame({'RMSE': [rmse_value]})
    rmse_df.to_csv(subfolder_path + 'rmse_valueBisquert.csv', index=False)
    print("RMSE value saved to rmse_valueBisquert.csv")


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
    KKresults_df.to_csv(subfolder_path + 'kkResults.csv', index=False)
    print("Results saved to kkResults.csv")

    # Ensure lengths match before creating the DataFrame
    parameter_names = ['R_m', 'R_k', 'Q', 'alpha', 'L']
    if len(parameter_names) == len(fitted_params):
        params_df = pd.DataFrame({'Parameter': parameter_names, 'Value': fitted_params})
        params_df.to_csv(subfolder_path + 'fitted_params.csv', index=False)
        print("Fitted parameter values saved to fitted_params.csv")
    else:
        print(f"Length mismatch: {len(parameter_names)} parameters but {len(fitted_params)} fitted values.")

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



