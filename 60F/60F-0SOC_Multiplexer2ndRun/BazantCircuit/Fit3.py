import pandas as pd
import numpy as np
import matplotlib.pyplot as plt
from impedance.models.circuits import CustomCircuit
from impedance.visualization import plot_nyquist, plot_residuals
from impedance import preprocessing
from impedance.preprocessing import saveCSV
from impedance.models.circuits.fitting import circuit_fit, rmse

# Define the path to the subfolder
subfolder_path = 'C:/Users/DankyATM/Downloads/60F/60F-0SOC_Multiplexer2ndRun/'

# Load data from the example EIS data
frequencies, Z = preprocessing.readCSV(subfolder_path + '60F-0SOC_Multiplexer2ndRun_0%SOC_AfterMath_Real&Imag.csv')

# Ignore Below X-axis 
frequencies, Z = preprocessing.ignoreBelowX(frequencies,Z)

# Define the circuit:
circuit = 'R0-C0-p(R1,W)'
initial_guess = [7.43197184e-03, 60, 1.51505406e+02,1e-5]  # Updated initial guesses

# Fit the circuit model using basinhopping for global optimization
try:
    p_values, p_errors = circuit_fit(frequencies, Z, circuit, initial_guess, global_opt=True)
    
    # Create the CustomCircuit with fitted parameters
    circuit_model = CustomCircuit(circuit=circuit, initial_guess=initial_guess)
    circuit_model.parameters_ = p_values

    # Predict impedance using the fitted circuit model
    Z_fit = circuit_model.predict(frequencies)

    # Get the fitted parameters
    fitted_params = circuit_model.parameters_
    print("Fitted parameters:", fitted_params)
    print("Parameter errors:", p_errors)

    # Save the fitted data to a CSV file in the specified subfolder
    saveCSV(subfolder_path + 'fitted_data_BazantCircuit.csv', frequencies, Z_fit)

    # Calculate residuals
    res_meas_real = np.sqrt((Z - Z_fit).real ** 2)
    res_meas_imag = np.sqrt((Z - Z_fit).imag ** 2)

    # Normalize residuals by the magnitude of the original data
   

    # Create a DataFrame to save the errors along with the frequencies
    error_df = pd.DataFrame({
        'Frequency': frequencies,
        'Real_Error': res_meas_real,
        'Imag_Error': res_meas_imag
    })

    # Save the error data to a CSV file in the specified subfolder
    error_df.to_csv(subfolder_path + 'impedance_fit_errors_BazantCircuit.csv', index=False)
    print("Errors saved to impedance_fit_errors_impedance_fit_errors_BazantCircuit.csv")

    # Calculate RMSE between the fit and the data
    rmse_value = rmse(Z, Z_fit)
    print("RMSE:", rmse_value)

    # Save the RMSE value to a CSV file
    rmse_df = pd.DataFrame({'RMSE': [rmse_value]})
    rmse_df.to_csv(subfolder_path + 'rmse_value_BazantCircuit.csv', index=False)
    print("RMSE value saved to rmse_value_BazantCircuit.csv")

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

