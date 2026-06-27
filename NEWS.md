# grainsizeR 0.0.0.9000

## Development version

- Display lower open-ended grain-size classes at 0.002 mm on distribution and
  cumulative log plots without changing calculations.
- Fixed log-scaled distribution plots so centered bars use the original
  particle-size class values after unit conversion.
- Added a plotting-only GRADISTAT Trace guide while preserving workbook-derived
  gravel classification thresholds, and restored centered distribution bars for
  log-scaled grain-size displays.
- Corrected GRADISTAT gravel-sand-mud ternary plot geometry for the central
  sand/mud boundary and slightly gravelly band, and drew log-scaled
  distribution bars from true size-class boundaries.
- Polished ternary diagram guide placement and boundary styling, and restored
  single-sample log-scaled grain-size distribution and cumulative plots using
  millimetre particle-size axes.
- Tuned GRADISTAT and USDA ternary labels, restored a missing GRADISTAT
  gravel-band boundary, and added `particle_unit` controls for log-scaled
  distribution and cumulative plots.
- Refined ternary plot output so USDA and GRADISTAT plots hide Cartesian axes,
  draw ternary axis guides, correct GRADISTAT gravel-sand-mud orientation, and
  keep the top gravel field continuous.
- Updated distribution and cumulative plots to use plain log-scaled
  particle-size tick labels and default sample faceting for multi-sample
  displays.
- Polished plotting defaults and README showcase outputs, including
  `theme_bw()`-based plot functions, combined distribution/cumulative displays,
  gravel-sand-mud fraction plotting, YlOrBr fraction palettes, and USDA ternary
  plot class boundaries.
- Added reproducible README showcase figures for dry-sieve GRADISTAT-style
  workflows and long-format USDA texture workflows.
- Prepared public GitHub repository materials, including contribution guidance,
  issue templates, citation metadata, security notes, and a lightweight check
  workflow.
- Clarified preferred, convenience, compatibility, advanced, and low-level
  exported functions.
- Added convenience aliases for common grain-size workflows and introduced
  `plot_texture_ternary()` as a terminology-correct plotting alias.
- Added full workflow vignettes for grain-size analysis, texture
  classification, and replacing GRADISTAT/G2Sd-style workflows.
- Hardened GRADISTAT/G2Sd plot API contracts.
- Added GRADISTAT-style ternary plotting for gravel-sand-mud and
  sand-silt-clay no-gravel bases.
- Added GRADISTAT-style sediment-name composition support.
- Added GRADISTAT-style texture classification for gravel-sand-mud and
  sand-silt-clay no-gravel bases.
- Added GRADISTAT-style descriptive terminology and quality-warning support.
- Added GRADISTAT-style D-spread descriptors and mode support.
- Added a source-grounded GRADISTAT/G2Sd replacement audit matrix and
  terminology cleanup for release planning.
- Improved user-facing documentation, examples, API contract tests, and
  performance notes for USDA major texture classification.
- Added public USDA 12-class major texture classification through the existing
  `classify_texture()` workflow.
- Resolved synthetic coverage-grid gaps in the internal USDA major texture rule helper.
- Added coverage-grid, edge-case, and performance preflight checks for the internal USDA major texture rule helper.
- Added an internal USDA major texture rule helper validated against official, targeted, and boundary validation points.
- Compared filled USDA boundary validation results and revised proposed major-class rules.
- Added boundary validation candidates for unresolved USDA proposed-rule cases.
- Added USDA proposed-rule conflict review and internal classifier design notes.
- Added validation of proposed USDA major texture-class rules from user-filled review workspaces.
- Added a manual USDA correction workspace for geometry and future simple-rule review.
- Added USDA geometry diagnostics and a performance-oriented simple-rule review plan.
- Compared targeted USDA sandy-loam / loam official validation results and documented secondary diagnostic-use restrictions.
- Added targeted USDA validation candidates for the remaining sandy-loam / loam mismatch group.
- Added USDA official validation candidate and result-capture workflow.
- Added USDA official validation comparison workflow for reconstruction points.
- Added USDA official validation mismatch review and correction-planning workflow.
- Applied user-reviewed USDA coordinate corrections and reran validation checks.
- Ingested user-reviewed full USDA revised coordinate table and reran validation checks.
- Added internal USDA geometry/classification self-check scripts.
- Ingested user-provided USDA coordinate-entry rows and passed schema and geometry QC.
- Added USDA coordinate-entry guardrails and review templates for future independent reconstruction.
- Added USDA coordinate reconstruction working-table QC infrastructure.
- Added USDA boundary-rule review and coordinate-reconstruction protocol scaffolds.
- Added USDA texture class-system and boundary-rule provenance tables.
- Added exact USDA source-location and figure/page verification records.
- Added USDA source review and provisional reconstruction-basis documentation.
- Populated USDA source manifest and evidence ledger with candidate official USDA/NRCS sources.
- Prepared GitHub pre-release documentation and repository templates.
- Added MIT licensing and formal data/provenance policy for future official texture polygon datasets.
- Added `gs_diagnostics()` for data quality and resolvability checks before summary statistics and texture workflows.
- Added a dry-sieve versus sieve + hydrometer workflow vignette using the package example datasets.
- Clarified that long and wide input formats are independent of laboratory measurement workflows; pipette, laser-diffraction, and other datasets can be imported when arranged as retained size-class values.
- Added an official texture polygon dataset roadmap and source-prioritization policy.
- Added long and wide grain-size input.
- Added cumulative curves, D-values, and percent-finer interpolation.
- Added grain-size indices, Folk and Ward statistics, and moment statistics.
- Added particle-size fraction schemes and particle-size system registry.
- Added source-audit registry for planned texture classification systems.
- Added plotting helpers for distributions, cumulative curves, fractions, and texture ternary plots.
- Added user-supplied texture polygon validation and classification framework.
- Added USDA source-verification notes for future texture triangle reconstruction.
- Added coordinate-free source verification notes for planned non-USDA texture systems.
- Added a source-audit crosswalk for selected field soil description standards.
- Added a coordinate-free polygon reconstruction template and checklist for future official texture datasets.
- Added helper functions for converting polygon reconstruction tables into validated texture polygon schemas.
- Added a coordinate-free USDA texture-triangle reconstruction dry-run scaffold.
- Added USDA source manifest and evidence ledger scaffolds for provenance tracking.
- Added generic source and reconstruction scaffolds for planned non-USDA texture polygon candidates.
- Added a GRADISTAT-inspired grain-size summary plot.
- Clarified the summary-table workflow using `gs_parameters()` instead of adding a dedicated export helper.
- Added numerical validation tests and a method-validation vignette using both synthetic examples and package example data.
- Performed release-candidate API and documentation audit.
