# 1F SOC Plot Variants

This folder holds optional MATLAB plot scripts for the 1F data.

The main SOC scripts live one level up:

- `SOCPlot.m`
- `SOCFitPlot.m`

## Scripts

| Script | Use | Check |
| --- | --- | --- |
| `PlottingBasic.m` | Basic measured-data plot. | Saves a PDF to `Figures/`. |

This is a short script that calls the common plotting files in `plotting/`.
For normal use, start with `SOCPlot.m` and `SOCFitPlot.m`.

Run variants from the parent `SOC` folder:

```matlab
cd 1F/SOC
run('plot_variants/PlottingBasic.m')
```

`tests/generate_matlab_plot_variants.m` runs this script with MATLAB figures hidden.
