# 1F SOC Plot Variants

This folder holds older or one-off MATLAB plotting scripts for the 1F data.

The main SOC scripts live one level up:

- `SOCPlot.m`
- `SOCFitPlot.m`

## Scripts

| Script | Use | Batch status |
| --- | --- | --- |
| `PlottingBasic.m` | Older basic measured-data plot. | Fails unless `SingleTest-Vertification/fitted_dataBasic.csv` is restored. |

Run variants from the parent `SOC` folder:

```matlab
cd 1F/SOC
run('plot_variants/PlottingBasic.m')
```

Batch status was checked with `tests/audit_matlab_variants.m`.
