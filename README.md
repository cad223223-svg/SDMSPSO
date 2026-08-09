# SDMSPSO

Official MATLAB implementation accompanying the manuscript:

> **Synergistic dual-scale multi-surrogate particle swarm optimization for high-dimensional expensive optimization**

SDMSPSO coordinates a macro-scale separable quadratic search with a micro-scale heterogeneous local search under one archive and one expensive-evaluation budget. The micro engine combines a local separable quadratic model, a truncated-SVD Gaussian-RBF surrogate, and random-subspace coordinate search. An improvement-driven trust region controls the local radius.

## Requirements

- MATLAB R2024b (the version used in the paper)
- Statistics and Machine Learning Toolbox (`lhsdesign`)
- PlatEMO v4.15, downloaded separately from <https://github.com/BIMK/PlatEMO/releases>

PlatEMO is not redistributed here. Its copyright belongs to the BIMK Group and its own terms apply.

## Repository layout

```text
algorithms/SDMSPSO/SDMSPSO.m       Main algorithm and ablation switches
problems/UAVPathPlanning3D/         500-D UAV penalty problem
experiments/                         Reproduction and plotting functions
config/paper_settings.m             Settings used in the manuscript
docs/REPRODUCIBILITY.md              Exact experiment matrix and caveats
```

## Installation

Clone this repository and PlatEMO, then in MATLAB run:

```matlab
addpath(genpath('path/to/PlatEMO/PlatEMO'));
addpath(genpath('path/to/SDMSPSO-GitHub'));
```

## Quick start

Run one paper-style benchmark configuration:

```matlab
out = run_single_experiment('SDMSPSO', 'SOP_F1', 30, 1000, 50, 1, {0.4,150,1,1,1}, {});
disp(out.bestObjective)
```

Run the complete SDMSPSO benchmark matrix (8 functions × 6 dimensions × 20 runs):

```matlab
run_benchmark_suite('results/benchmarks');
```

Run the three UAV scenarios:

```matlab
run_uav_suite('results/uav');
plot_uav_results('results/uav', 'results/figures');
```

These full experiments are computationally expensive. For a smoke test:

```matlab
run_smoke_test;
```

## Paper-consistent settings

- Benchmarks: `SOP_F1`, `SOP_F5`, `SOP_F8`–`SOP_F13`
- Dimensions: 30, 50, 100, 200, 500, and 1000
- `MaxFE = 1000`, `N = 50`, 20 independent runs
- Initial LHS size: 100 for `D < 100`; 150 for `D >= 100`
- `TR_init = TR_max = 0.4`, `TR_min = 1e-6`
- `K_loc_max = 150`, active rank at most 20
- Micro PSO: 50 particles and 30 generations
- UAV: 500 variables, 250 intermediate waypoints, 300 spline samples, three scenarios

The algorithm accepts five parameters:

```text
{TR_init, K_loc_max, useMacroQuadratic, useLRSS, useAdaptiveTR}
```

The default is `{0.4,150,1,1,1}`. The ablation runner uses the same implementation with one component disabled at a time, avoiding drift between duplicated source files.

## Important interpretation

The UAV objective uses soft penalties. A lower objective means a lower combined length, threat, collision, altitude, and smoothness cost; it is not a certificate of hard collision-free feasibility.

The diagnostic held-out objective calls used for the paper's surrogate-error/TR analysis are intentionally not embedded in `SDMSPSO.m`. This prevents uncounted diagnostic evaluations during ordinary optimization. They do not affect the benchmark rankings in the paper.

## Citation

Please cite the associated manuscript and PlatEMO:

The repository's `CITATION.cff` currently cites software version 1.0.0. Add the article DOI, volume, pages, and final publication year after acceptance; no publication metadata is guessed in this release.

```bibtex
@article{Tian2017PlatEMO,
  title   = {PlatEMO: A MATLAB Platform for Evolutionary Multi-Objective Optimization},
  author  = {Tian, Ye and Cheng, Ran and Zhang, Xingyi and Jin, Yaochu},
  journal = {IEEE Computational Intelligence Magazine},
  volume  = {12},
  number  = {4},
  pages   = {73--87},
  year    = {2017}
}
```

## License

The SDMSPSO-specific code in this repository is released under the MIT License. PlatEMO and any baseline implementations remain subject to their respective terms.
