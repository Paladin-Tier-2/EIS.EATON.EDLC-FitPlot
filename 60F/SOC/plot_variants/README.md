# 60F SOC Plot Variants

This folder holds publication-style plot variants and one-off analysis scripts
for the 60F data.

The main SOC scripts live one level up:

- `SOCPlot.m`
- `SOCFitPlot.m`

## Scripts

| Script | Use | Batch status |
| --- | --- | --- |
| `SOCFitPlot_Standard.m` | Older fit plot variant. | Fails in batch on old axis-limit handling. |
| `SOCFitPlot_HorizontalLegend.m` | Fit plot with a horizontal legend layout. | Fails in batch on old axis-limit handling. |
| `SOCFitPlot_VerticalLegend.m` | Fit plot with a vertical publication legend. | Fails in batch on old axis-limit handling. |
| `SOCPlot_FrequencyLabel.m` | Measured-data plot with frequency labels and draggable annotations. | Fails in batch; old manual annotation workflow. |
| `MaxPower.m` | One-off max-power analysis plot. | Runs in batch. |

The frequency-label script has manual/interactive annotation code. The normal
entry points are still `SOCPlot.m` and `SOCFitPlot.m`.

Run variants from the parent `SOC` folder:

```matlab
cd 60F/SOC
run('plot_variants/SOCFitPlot_VerticalLegend.m')
```

Batch status was checked with `tests/audit_matlab_variants.m`.
