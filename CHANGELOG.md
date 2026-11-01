# Changelog

## 1.1.0 — 2026-11-01

- Corrected the broad ablation switch so `wo-LQS` disables only the local quadratic candidate.
- Added paired `wo-OCD` and OCD grid-resolution runners matching the manuscript protocols.
- Added a post hoc 300/3000-sample UAV geometry audit for saved trajectories.
- Documented the distinction between newly seeded reruns and historical paper results.

## 1.0.0 — 2026-08-09

- Prepared a standalone PlatEMO v4.15 add-on repository.
- Replaced corrupted comments with English documentation.
- Removed uncounted diagnostic `CalObj` calls from the main optimizer.
- Unified ablations through explicit component switches.
- Renamed and corrected the reported `wo-LRSS` ablation.
- Matched the sensitivity study to SOP-F1, SOP-F5, and SOP-F11 at D=200.
- Restricted the UAV release to the paper's three scenarios.
- Corrected UAV plotting to use split-half `[Y,Z]` decoding and the evaluated cubic spline.
- Added deterministic seeds, compact result files, citation metadata, and an MIT license.

