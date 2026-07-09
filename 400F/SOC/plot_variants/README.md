# 400F SOC Plot Variants

This folder holds optional MATLAB plot scripts for the 400F data.

The main SOC scripts live one level up:

- `SOCPlot.m`
- `SOCFitPlot.m`

## Scripts

| Script | Use | Check |
| --- | --- | --- |
| `SOCFitPlot_VerticalLegend.m` | Fit plot kept for the older output name. | Saves a PDF to `Figures/`. |
| `SOCPlot_FrequencyLabel.m` | Measured-data plot with frequency labels. | Saves a PDF to `Figures/`. |
| `RelativeError.m` | Relative-error plot from fitted error CSVs. | Saves a PDF to `Figures/`. |
| `MaxPower.m` | Max-power plot from fitted `R_0` values. | Saves a PDF to `Figures/`. |

These are short scripts that call the common plotting files in `plotting/`. For
normal use, start with `SOCPlot.m` and `SOCFitPlot.m`.

Run variants from the parent `SOC` folder:

```matlab
cd 400F/SOC
run('plot_variants/SOCFitPlot_VerticalLegend.m')
```

`tests/audit_matlab_variants.m` runs these scripts with MATLAB figures hidden.
