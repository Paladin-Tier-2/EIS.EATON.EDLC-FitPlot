# EIS_EATON_EDLC_FittingAndPlotting

## Overview
This project is designed to facilitate the processing, fitting, and plotting of Electrochemical Impedance Spectroscopy (EIS) data specifically for EDLC (Electric Double Layer Capacitor) devices from EATON. The data is sourced from Solatron files and processed using the `impedance.py` script. The script provides an automated fitting solution across various States of Charge (SOC) for a given architecture. MATLAB is utilized for extensive and detailed plotting of the results.

## Features
- **Data Extraction**: Reads and extracts EIS data from Solatron files for further processing.
- **Automated Fitting**: The `impedance.py` script fits the EIS data for all different SOCs with a single button press, streamlining the fitting process.
- **Advanced Plotting**: MATLAB provides extensive plotting capabilities, allowing for detailed visualization of the fitting results across different SOCs.

## Directory Structure
- **1F**: Contains data and results for the 1F EDLC device.
- **400F**: Contains data and results for the 400F EDLC device.
- **60F**: Contains data and results for the 60F EDLC device.
- **README.md**: This file.

## Usage
1. **Prepare the Data**: Ensure your EIS data from Solatron files is available and organized in the appropriate directories (`1F`, `400F`, `60F`).
2. **Run the Fitting Script**: Execute `impedance.py` to automatically fit the EIS data across all SOCs.
3. **Plot the Results**: Use MATLAB to visualize the fitting results with its extensive plotting capabilities.

## Requirements
- **Python**: Ensure you have Python installed.
- **MATLAB**: MATLAB for plotting the results.
- **Dependencies**: Install any necessary Python libraries using `pip install -r requirements.txt`.

## Getting Started
1. **Clone the Repository**:
   ```bash
   git clone https://github.com/yourusername/EIS_EATON_EDLC_FittingAndPlotting.git
   cd EIS_EATON_EDLC_FittingAndPlotting
