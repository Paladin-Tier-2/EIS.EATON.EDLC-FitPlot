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

# Initial Guess + Constant = Parameters
# initial_guess = [8.69066477e-02, 7.19786672e+01, 1, 1, 9.85757029e-01]
initial_guess = [8.69066477e-02, 7.19786672e+01, 1, 1, 9.85757029e-01,1]

# Bounds for your entire circuit 
#bounds = ([1e-2, 0, 0, 0.5, 0.5], [10e-2, np.inf, np.inf, 1.5, 1])

bounds = ([1e-2, 0, 0, 0.5, 0.5,0], [10e-2, np.inf, np.inf, 1.5, 1,np.inf])

# Fit the circuit model using basinhopping for global optimization
try:
   # p_values, p_errors = circuit_fit(frequencies, Z, circuit, initial_guess, constants={'B_1_4': 1}, bounds=bounds, global_opt=True)
    p_values, p_errors = circuit_fit(frequencies, Z, circuit, initial_guess, bounds=bounds, global_opt=True)
    
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

    tc_distribution = get_tc_distribution(frequencies,M)
    # Save the time-constant distribution to a CSV file
    tc_df = pd.DataFrame({'Time_Constant': tc_distribution})
    tc_df.to_csv(subfolder_path + 'tc_distribution.csv', index=False)
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


    # Plot the time-constant distribution
    plt.figure(figsize=(10, 6))
    plt.plot(tc_distribution, marker='o', linestyle='-')
    plt.xlabel('Index')
    plt.ylabel('Time Constant')
    plt.title('Time-Constant Distribution')
    plt.grid(True)
    plt.savefig(subfolder_path + 'tc_distribution_plot.png')
    plt.show()

except Exception as e:
    print("An error occurred during the fitting process:", e)
