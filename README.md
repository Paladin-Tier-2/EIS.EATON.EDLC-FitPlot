# EIS EATON EDLC Fitting And Plotting

## Overview
This project is designed to facilitate the processing, fitting, and plotting of Electrochemical Impedance Spectroscopy (EIS) data specifically for EDLC (Electric Double Layer Capacitor) devices from EATON. The data is sourced from Solatron files and processed using the `impedance.py` script. The script provides an automated fitting solution across various States of Charge (SOC) for a given architecture. MATLAB is utilized for extensive and detailed plotting of the results.

## Features
- **Data Extraction**: Reads and extracts EIS data from Solatron files for further processing.
- **Automated Fitting**: The `impedance.py` script fits the EIS data for all different SOCs with a single button press, streamlining the fitting process.
- **Advanced Plotting**: MATLAB provides extensive plotting capabilities, allowing for detailed visualization of the fitting results across different SOCs.

## Directory Structure
- **1F**: Contains data and results for the 1F EDLC device. This includes the fitting and plotting 
- **400F**: Contains data and results for the 400F EDLC device. This includes the fitting and plotting 
- **60F**: Contains data and results for the 60F EDLC device.  This includes the fitting and plotting 
- **README.md**: This file.

## Usage
1. **Prepare the Data**: Ensure your EIS data from Solatron files is available and organized in the appropriate directories (`1F`, `400F`, `60F`).
2. **Run the Fitting Script**: Execute `impedance.py` to automatically fit the EIS data across all SOCs.
3. **Plot the Results**: Use MATLAB to visualize the fitting results with its extensive plotting capabilities.

## Requirements
- **Python**: Ensure you have Python installed.
- **MATLAB**: MATLAB for plotting the results.
- **Dependencies**: Install any necessary Python libraries using `pip install -r requirements.txt`.

## Getting Started with impedance.py
For detailed instructions on setting up and using `impedance.py`, including installing Miniconda, creating a conda environment, and installing necessary packages, please refer to the [impedance.py Getting Started Guide](https://impedancepy.readthedocs.io/en/latest/getting-started.html).
## Using Visual Studio with Impedance.py 
To be able to use impedance.py with VS Code ( VS code being your conda environment ) 
follow this guide [Setting up Miniconda in VS Code](https://youtu.be/U3VAqCTujpg?si=bYmLjrdf4VCbd4kI) once after installing impedance.py with ```pip install impedance ``` in your desginated terminal.

### Quick Setup
1. **Clone the Repository**:
   ```bash
   git clone https://github.com/yourusername/EIS_EATON_EDLC_FittingAndPlotting.git
   cd EIS_EATON_EDLC_FittingAndPlotting



##
Name the circuit element that is associated with ESR as 'R_0' for Bisquert Open Circuits
