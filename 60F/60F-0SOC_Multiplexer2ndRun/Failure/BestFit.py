import pandas as pd
import numpy as np
import matplotlib.pyplot as plt
from impedance.models.circuits import CustomCircuit
from impedance.visualization import plot_nyquist, plot_residuals
from impedance import preprocessing
from impedance.preprocessing import saveCSV
from itertools import product
from joblib import Parallel, delayed

# Load data from the example EIS data
frequencies, Z = preprocessing.readCSV('C:/Users/DankyATM/Downloads/60F/60F-0SOC_Multiplexer2ndRun/60F-0SOC_Multiplexer2ndRun_0%SOC_AfterMath_Real&Imag.csv')
# Keep only the impedance data in the first quadrant
frequencies, Z = preprocessing.ignoreBelowX(frequencies, Z)

# Fixed R0 and define a range of possible initial guesses for each parameter
R0 = 0.00745  # Ohms, fixed as per your instructions
R1_range = np.linspace(0.008, 0.02, 5)  # Adjusted range for R1
Q_range = np.linspace(30, 60, 4)        # Adjusted range for Q
n_range = np.linspace(0.8, 1.0, 5)      # CPE exponent
Wo0_range = np.linspace(1e-3, 0.1, 6)   # Adjusted range for Wo0
Wo1_range = np.linspace(1e-3, 0.1, 6)   # Adjusted range for Wo1

# Define a function to fit a model and calculate the error
def fit_model(R1, Q, n, Wo0, Wo1):
    initial_guess = [R0, R1, Q, n, Wo0, Wo1]
    circuit = 'R0-p(R1,CPE1)-Wo1'
    model = CustomCircuit(circuit, initial_guess=initial_guess)
    model.fit(frequencies, Z)
    fit_error = np.sum(np.abs(Z - model.predict(frequencies))**2)
    return model, fit_error

# Use parallel processing to speed up the search for the best fit
results = Parallel(n_jobs=-1)(delayed(fit_model)(R1, Q, n, Wo0, Wo1) 
                              for R1, Q, n, Wo0, Wo1 in product(R1_range, Q_range, n_range, Wo0_range, Wo1_range))

# Find the best fit among the results
best_fit, lowest_error = min(results, key=lambda x: x[1])

print("Best fit parameters:", best_fit.parameters_)
