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
print(frequencies)
