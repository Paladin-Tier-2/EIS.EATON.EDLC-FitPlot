import pandas as pd
import numpy as np
import matplotlib.pyplot as plt
from impedance.models.circuits import CustomCircuit
from impedance.visualization import plot_nyquist, plot_residuals
from impedance import preprocessing
from impedance.preprocessing import saveCSV

# Define the path to the subfolder
subfolder_path = 'C:/Users/DankyATM/Downloads/60F/60F-0SOC_Multiplexer2ndRun/'

# Load data from the example EIS data
frequencies, Z = preprocessing.readCSV('C:/Users/DankyATM/Downloads/60F/60F-0SOC_Multiplexer2ndRun/60F-0SOC_Multiplexer2ndRun_0%SOC_AfterMath_Real&Imag.csv')
# Keep only the impedance data in the first quadrant
frequencies, Z = preprocessing.ignoreBelowX(frequencies, Z)

# Define the circuit:
#circuit = 'R0-L0-p(R1,CPE1)-Wo'
#initial_guess = [0.0074, 0.009, 0.003, 60, 0.9, 0.1, 0.5]  # Updated initial guesses

circuit = 'R0-p(R1,CPE1)-Wo'
initial_guess = [0.0074, 0.003, 60, 0.9, 0.1, 0.5]  # Updated initial guesses

# Create the CustomCircuit
circuit_model = CustomCircuit(circuit=circuit, initial_guess=initial_guess)

# Fit the circuit model to the data
circuit_model.fit(frequencies, Z)

# Predict impedance using the fitted circuit model
Z_fit = circuit_model.predict(frequencies)


# Get the fitted parameters
fitted_params = circuit_model.parameters_
print("Fitted parameters:", fitted_params)

# Save the fitted data to a CSV file
saveCSV('fitted_data2.csv', frequencies, Z_fit)


# Plot the Nyquist plot
# Plotting the Nyquist plot with a larger figure size
fig, ax = plt.subplots()


plot_nyquist(Z, fmt='o', scale=1, ax=ax)
plot_nyquist(Z_fit, fmt='-', scale=1, ax=ax)
plt.legend(['Data', 'Fit'])
plt.title('Nyquist Plot')
plt.show()

