# Reproducibility notes

## Paper experiment matrix

The benchmark study uses eight PlatEMO SOP functions (`F1`, `F5`, and `F8`–`F13`), dimensions 30/50/100/200/500/1000, `MaxFE=1000`, `N=50`, and 20 independent runs. `run_benchmark_suite` reproduces the SDMSPSO portion of this 960-run matrix.

The sensitivity study is intentionally limited to SOP-F1, SOP-F5, and SOP-F11 at `D=200`, matching the manuscript. It tests `TR_init` in `{0.2,0.4,0.8}` with `K_loc_max=150`, and `K_loc_max` in `{50,100,150,200}` with `TR_init=0.4`.

The ablation study uses all eight functions at dimensions 30, 200, and 500. The variants are implemented by switches in the same `SDMSPSO.m` file:

- `wo-Quad`: disables the macro separable-quadratic candidates.
- `wo-LQS`: disables only the local separable-quadratic candidate; SVD-RBF and OCD remain active.
- `wo-ATR`: holds the trust-region radius fixed.

The legacy `useLRSS=0` switch disables all three local candidates and is not
used for the manuscript's `wo-LQS` comparison. The focused OCD ablation uses
paired seeds for the full algorithm and `wo-OCD` on the same eight functions at
30, 200, and 500 variables (20 pairs per configuration). The grid-resolution
study tests 9, 13, 21, 31, and 41 points on F1, F5, and F11 at 200 variables
(20 independent runs per setting). These scripts generate new data rather than
recovering the historical run-level results behind published tables.

## UAV encoding

The 500-D decision vector is exactly `[y_1,...,y_250,z_1,...,z_250]`. The plotting function calls the same `DecodeTrajectory` routine used by the objective. It does not use odd/even indexing and does not apply extra smoothing, both of which would produce a plotted path different from the evaluated path.

The manuscript reports three scenarios only. A fourth exploratory scenario found in the working PlatEMO directory is excluded from this release.

`audit_uav_geometry` checks each saved SDMSPSO best decision at 300 and 3000
spline samples. It records sample-feasibility, terrain-clearance violations,
restricted-zone entry, and minimum clearance. This is a post hoc sampled
geometric check, not a continuous-path safety certificate. The manuscript's
multi-algorithm UAV table also uses baseline trajectories not included here.

## Random seeds

The original paper states independent MATLAB pseudorandom initialization but does not publish every seed. The release uses deterministic, configuration-specific seeds derived from `seedBase`, so future reruns are auditable. Exact numerical identity with historical unrecorded runs is therefore not guaranteed.

## Diagnostic evaluations

The historical working file embedded ten held-out `Problem.CalObj` calls per iteration to study surrogate error versus trust-region radius. Those calls were not inserted into the archive and did not affect candidate selection, but they were outside `MaxFE`. They have been removed from the public optimization implementation so that ordinary runs contain no hidden diagnostic objective calls.

## Baselines and data

Baseline implementations and the SOP problems are supplied by PlatEMO v4.15 and are not copied into this repository. Large raw `.mat` archives are also excluded. Each release runner stores compact per-run summaries containing the best objective, best decision, runtime, seed, and configuration.


