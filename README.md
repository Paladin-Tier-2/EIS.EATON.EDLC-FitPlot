# EIS EATON EDLC Fit Plot

This repo contains electrochemical impedance spectroscopy (EIS) data and scripts
used for fitting and plotting EATON electric double-layer capacitors (EDLCs).

The workflow is split between MATLAB and Python:

- MATLAB extracts the useful columns from exported measurement CSV files.
- Python fits equivalent-circuit models with the `impedance` package.
- MATLAB makes the Nyquist plots, fit plots, error plots, power plots, and some
  LaTeX tables.

The repo includes measured data and generated fit outputs for `1F`, `60F`, and
`400F` capacitors at different states of charge.

## Repository Layout

```text
.
|-- ExtractNyquistAllSoc.m
|-- eis_fit_workflow.py
|-- eis_table_workflow.py
|-- 1F/
|   `-- SOC/
|-- 60F/
|   `-- SOC/
`-- 400F/
    `-- SOC/
```

Each capacitor folder follows the same basic pattern:

```text
<capacitance>F/SOC/<SOC>%SOC/
```

Examples:

```text
1F/SOC/40%SOC/
60F/SOC/80%SOC/
400F/SOC/100%SOC/
```

Inside each SOC folder, the important file types are:

| File pattern | Meaning |
| --- | --- |
| `<cap>F-<SOC>SOC.csv` | Original exported measurement CSV |
| `<cap>F-<SOC>%SOC_Python.csv` | Three-column file used by Python: frequency, real impedance, imaginary impedance |
| `<cap>F-<SOC>%SOC_Fit.csv` | Fitted impedance data |
| `<cap>F-<SOC>%SOC_Fit_params.csv` | Fitted circuit parameters |
| `<cap>F-<SOC>%SOC_Fit_errors.csv` | Fit residuals/errors |
| `<cap>F-<SOC>%SOC_Fit_rmse.csv` | RMSE for the fit |
| `<cap>F-<SOC>%SOC_Fit_mu.csv` | Lin-KK `mu` value |
| `<cap>F-<SOC>%SOC_Fit_kkResults.csv` | Lin-KK summary values |

The folder name and file names matter. The scripts expect names like `40%SOC`
and `400F-40%SOC_Python.csv`.

## Requirements

Python:

```bash
pip install -r requirements.txt
```

Main Python packages:

- `impedance`
- `numpy`
- `pandas`
- `matplotlib`

MATLAB:

- MATLAB with `readtable`, `readmatrix`, and standard plotting functions.
- The plotting scripts also call `PLOT_STANDARDS`, `STANDARDIZE_FIGURE`, and
  `SAVE_MY_FIGURE`. Those are not included in this repo. They come from the
  Professional Plots setup used for the original plots.

## Data Extraction

Use `ExtractNyquistAllSoc.m` to create the `_Python.csv` files from the exported
measurement CSV files.

Run it from MATLAB:

```matlab
ExtractNyquistAllSoc
```

When prompted, enter the capacitor folder name:

```text
1F
60F
400F
```

The script looks for:

```text
<capacitance>F/SOC/*%SOC/
```

For each SOC folder, it reads the canonical measurement CSV and writes:

```text
<capacitance>F-<SOC>%SOC_Python.csv
```

The extraction currently uses columns 6, 11, and 12 from the exported CSV:

- frequency
- real impedance
- imaginary impedance

The notes and screenshots in `1F/SOC/Readme/` and `60F/SOC/Readme/` show the
expected folder setup and export style.

## Python Fitting

Run the fitting scripts from inside the matching `SOC` folder.

Example:

```bash
cd 1F/SOC
python FitAll_Bisquert.py
```

Other fitting scripts:

```text
1F/SOC/FitAll_Bisquert.py
1F/SOC/FitAll_Distinct.py
1F/SOC/FitAllCutoff.py
60F/SOC/FitAll.py
400F/SOC/FitAll_Bisquert.py
400F/SOC/FitAll_Distinct.py
```

These files are small wrappers around `eis_fit_workflow.py`. The wrappers keep
the model-specific settings near the data: circuit string, initial guesses,
bounds, parameter names, optional cutoff frequency, and whether to show a
diagnostic plot.

The shared workflow searches the SOC subfolders for `*_Python.csv`, fits the
configured circuit, and writes fit outputs next to the input files.

The Bisquert scripts use:

```text
R_0-B_1
```

The distinct model scripts use:

```text
R_1-Wo_1-p(CPE_1,R_2-CPE_2)
```

For the Bisquert open-circuit model, the ESR-related circuit element is named
`R_0`.

Important: running a fitting script writes new `_Fit*.csv` files. If existing
results matter, copy them somewhere else first.

## MATLAB Plotting

Run the plotting scripts from inside the matching `SOC` folder.

Example:

```matlab
cd 400F/SOC
SOCFitPlot
```

Useful MATLAB scripts:

| Script | Purpose |
| --- | --- |
| `SOCPlot.m` | Plot measured Nyquist data across SOC values |
| `SOCFitPlot.m` | Plot measured data with fitted curves |

Most plotting scripts expect to start in a `SOC` folder. They look for SOC
subfolders below the current directory and write figures to a local `Figures`
folder.

Some scripts ask which SOC values to omit from a plot.

Older plot variants and one-off analysis scripts are in `extras/` folders under
each `SOC` folder. This keeps the main folder readable without deleting useful
old plotting work. Examples include frequency-label plots, legend-layout
variants, `MaxPower.m`, `RelativeError.m`, and `PlottingBasic.m`.

## Tables

The table scripts collect generated fit results into LaTeX tables.

Examples:

```bash
cd 60F/SOC
python table.py
python ParamTable.py
```

Related scripts:

```text
1F/SOC/table.py
1F/SOC/ParamTable_Bisquert.py
1F/SOC/ParamTable_Distinct.py
60F/SOC/table.py
60F/SOC/ParamTable.py
400F/SOC/table.py
400F/SOC/ParamTable.py
400F/SOC/ParamTableDistinct.py
```

These scripts write `.tex` files into the same `SOC` folder.

The table scripts are wrappers around `eis_table_workflow.py`.

## Notes And Limitations

- This is a research/thesis workflow repo, not a packaged Python library.
- The data layout is part of the workflow. Renaming folders will break scripts
  unless the paths are updated.
- MATLAB plotting depends on local plotting helper functions that are not stored
  here.
- The Python fitting scripts contain model choices, bounds, and initial guesses
  directly in each file.
- The generated CSV results are committed so the repo can be inspected without
  rerunning all fits.
- Some plotting scripts have manual legend and axis settings. Adjust those in
  the script when making a new figure.

## Quick Start

For an existing dataset already in this repo:

```bash
pip install -r requirements.txt
cd 400F/SOC
python FitAll_Bisquert.py
```

Then in MATLAB:

```matlab
cd 400F/SOC
SOCFitPlot
```

For new exported measurement CSV files:

1. Put each measurement in the matching `<capacitance>F/SOC/<SOC>%SOC/` folder.
2. Run `ExtractNyquistAllSoc.m` from MATLAB and enter `1F`, `60F`, or `400F`.
3. Run the matching Python fitting script from the `SOC` folder.
4. Run the MATLAB plotting or table script from the same `SOC` folder.
