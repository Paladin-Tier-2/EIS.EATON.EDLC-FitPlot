import pandas as pd
import numpy as np
import matplotlib.pyplot as plt
from impedance.models.circuits import CustomCircuit
from impedance.visualization import plot_nyquist

# Load data from the provided CSV file using pandas
df = pd.read_csv(r'C:\Users\DankyATM\Downloads\60F\60F-0SOC_Multiplexer2ndRun\60F-0SOC_Multiplexer2ndRun_0%SOC_AfterMath_Real&Imag.csv')

# Display the first few rows and data types
print(df.head())
print(df.dtypes)
print(df.info())
