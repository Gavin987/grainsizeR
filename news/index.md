# Changelog

## grainsizeR 0.0.0.9000

### Development version

- Added long and wide retained grain-size import, validated `gsd_tbl`
  objects, diagnostics, D-values, percent-finer interpolation,
  grain-size indices, Folk and Ward statistics, moment statistics,
  modes, D-spread descriptors, parameter descriptions, quality flags,
  and summary-table workflows.
- Added particle-size fraction schemes, wide fraction summaries, and
  plotting helpers for retained distributions, cumulative curves,
  fractions, GRADISTAT- inspired summaries, and texture ternary plots.
- Added GRADISTAT-style texture classification, sediment-name
  composition, and gravel-sand-mud and sand-silt-clay no-gravel ternary
  plots.
- Added USDA 12-class major texture classification through
  `classify_texture(..., scheme = "usda", method = "rules")` and USDA
  ternary plotting without depending on external texture plotting
  packages.
- Added user-supplied texture polygon validation and classification
  workflows; built-in official texture polygon datasets are not bundled
  yet.
- Added workflow vignettes for grain-size analysis, texture
  classification, replacing GRADISTAT/G2Sd-style workflows, table
  layouts and measurement workflows, method validation, and
  user-supplied texture polygons.
- Added convenience aliases for common workflows, including
  [`plot_texture_ternary()`](https://Gavin987.github.io/grainsizeR/reference/plot_texture_ternary.md)
  as the preferred texture ternary plotting name while retaining
  compatibility aliases.
- Improved log-scaled distribution and cumulative plots with
  single-sample behavior, `particle_unit` controls, centered
  distribution bars, plain tick labels, and plotting-only lower
  open-tail display positions.
- Improved plotting ergonomics with numeric sample selection, clearer
  cumulative percentile markers, and texture ternary point controls for
  labels, constant aesthetics, and grouped color mapping.
- Updated bundled long and wide example CSV data and regenerated README
  examples and figures from those bundled files.
- Aligned pre-release texture APIs by using `texture_class_id` and
  `texture_class` for all
  [`classify_texture()`](https://Gavin987.github.io/grainsizeR/reference/classify_texture.md)
  methods, clarifying
  [`plot_texture_ternary()`](https://Gavin987.github.io/grainsizeR/reference/plot_texture_ternary.md)
  /
  [`plot_texture_triangle()`](https://Gavin987.github.io/grainsizeR/reference/plot_texture_triangle.md)
  alias roles, and making scheme validation errors more consistent.
- Renamed USDA texture triangle workflows to the single public scheme
  name `usda`; the pre-release `usda_tt` name has been removed before
  v0.1.0, and related documentation follow-ups were corrected.
- Refined GRADISTAT and USDA ternary plot guides, labels, boundaries,
  and README showcase figures; README PNG outputs are standardized to
  1000 px wide.
- Prepared GitHub pre-release documentation and repository templates,
  including contribution guidance, issue templates, citation metadata,
  security notes, and check workflows.
- Added MIT licensing and public provenance policy for future official
  texture polygon datasets.
