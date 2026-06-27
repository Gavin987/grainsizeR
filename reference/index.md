# Package index

## Input and validation

- [`read_gsd()`](https://Gavin987.github.io/grainsizeR/reference/read_gsd.md)
  : Read grain-size data from a delimited text file

- [`read_gsd_wide()`](https://Gavin987.github.io/grainsizeR/reference/read_gsd_wide.md)
  : Read wide-format grain-size data from a CSV file

- [`as_gsd_tbl()`](https://Gavin987.github.io/grainsizeR/reference/as_gsd_tbl.md)
  :

  Convert long-format grain-size data to a `gsd_tbl`

- [`is_gsd_tbl()`](https://Gavin987.github.io/grainsizeR/reference/is_gsd_tbl.md)
  : Test whether an object is a grain-size distribution tibble

- [`validate_gsd_tbl()`](https://Gavin987.github.io/grainsizeR/reference/validate_gsd_tbl.md)
  : Validate a grain-size distribution tibble

- [`gs_diagnostics()`](https://Gavin987.github.io/grainsizeR/reference/gs_diagnostics.md)
  : Diagnose grain-size data quality and resolvability

## Unit conversion

- [`mm_to_um()`](https://Gavin987.github.io/grainsizeR/reference/mm_to_um.md)
  : Convert millimeters to micrometers
- [`um_to_mm()`](https://Gavin987.github.io/grainsizeR/reference/um_to_mm.md)
  : Convert micrometers to millimeters
- [`mm_to_phi()`](https://Gavin987.github.io/grainsizeR/reference/mm_to_phi.md)
  : Convert millimeters to phi units
- [`phi_to_mm()`](https://Gavin987.github.io/grainsizeR/reference/phi_to_mm.md)
  : Convert phi units to millimeters
- [`um_to_phi()`](https://Gavin987.github.io/grainsizeR/reference/um_to_phi.md)
  : Convert micrometers to phi units
- [`phi_to_um()`](https://Gavin987.github.io/grainsizeR/reference/phi_to_um.md)
  : Convert phi units to micrometers

## Cumulative curves and D-values

- [`gs_cumulative()`](https://Gavin987.github.io/grainsizeR/reference/gs_cumulative.md)
  : Build cumulative grain-size boundary curves
- [`gs_d_values()`](https://Gavin987.github.io/grainsizeR/reference/gs_d_values.md)
  : Calculate grain-size percentiles
- [`gs_percent_finer()`](https://Gavin987.github.io/grainsizeR/reference/gs_percent_finer.md)
  : Calculate percent finer than grain-size thresholds
- [`gs_d_spread()`](https://Gavin987.github.io/grainsizeR/reference/gs_d_spread.md)
  : Calculate GRADISTAT-style D-spread descriptors

## Grain-size indices

- [`gs_grain_size_indices()`](https://Gavin987.github.io/grainsizeR/reference/gs_grain_size_indices.md)
  : Calculate additional grain-size indices
- [`gs_parameters()`](https://Gavin987.github.io/grainsizeR/reference/gs_parameters.md)
  : Summarize grain-size parameters
- [`gs_describe_parameters()`](https://Gavin987.github.io/grainsizeR/reference/gs_describe_parameters.md)
  : Attach GRADISTAT-style parameter descriptions
- [`gs_desc()`](https://Gavin987.github.io/grainsizeR/reference/gs_desc.md)
  : Convenience alias for descriptive parameter terms
- [`gs_quality_flags()`](https://Gavin987.github.io/grainsizeR/reference/gs_quality_flags.md)
  : Report GRADISTAT-inspired quality flags
- [`gs_qc()`](https://Gavin987.github.io/grainsizeR/reference/gs_qc.md)
  : Convenience alias for grain-size quality flags
- [`gs_size_terms()`](https://Gavin987.github.io/grainsizeR/reference/gs_size_terms.md)
  : Describe grain-size terms
- [`gs_modes()`](https://Gavin987.github.io/grainsizeR/reference/gs_modes.md)
  : Identify modal grain-size classes

## Folk and Ward statistics

- [`gs_folk_ward()`](https://Gavin987.github.io/grainsizeR/reference/gs_folk_ward.md)
  : Calculate Folk and Ward graphical grain-size statistics
- [`gs_fw57()`](https://Gavin987.github.io/grainsizeR/reference/gs_fw57.md)
  : Convenience alias for Folk and Ward graphical statistics
- [`describe_kurtosis_fw()`](https://Gavin987.github.io/grainsizeR/reference/describe_kurtosis_fw.md)
  : Describe Folk and Ward kurtosis
- [`describe_mean_size_phi()`](https://Gavin987.github.io/grainsizeR/reference/describe_mean_size_phi.md)
  : Describe mean grain size from phi units
- [`describe_skewness_fw()`](https://Gavin987.github.io/grainsizeR/reference/describe_skewness_fw.md)
  : Describe Folk and Ward skewness
- [`describe_sorting_fw()`](https://Gavin987.github.io/grainsizeR/reference/describe_sorting_fw.md)
  : Describe Folk and Ward sorting

## Moment statistics

- [`gs_moments()`](https://Gavin987.github.io/grainsizeR/reference/gs_moments.md)
  : Calculate grain-size moment statistics

## Fractions and particle-size systems

- [`particle_size_systems()`](https://Gavin987.github.io/grainsizeR/reference/particle_size_systems.md)
  : List built-in particle-size boundary systems
- [`texture_source_audit()`](https://Gavin987.github.io/grainsizeR/reference/texture_source_audit.md)
  : Inspect the texture source audit registry
- [`gs_fraction_schemes()`](https://Gavin987.github.io/grainsizeR/reference/gs_fraction_schemes.md)
  : List built-in grain-size fraction schemes
- [`gs_frac_schemes()`](https://Gavin987.github.io/grainsizeR/reference/gs_frac_schemes.md)
  : Convenience alias for fraction schemes
- [`gs_fractions()`](https://Gavin987.github.io/grainsizeR/reference/gs_fractions.md)
  : Calculate grain-size fraction percentages
- [`gs_frac()`](https://Gavin987.github.io/grainsizeR/reference/gs_frac.md)
  : Convenience alias for grain-size fractions
- [`gs_fractions_wide()`](https://Gavin987.github.io/grainsizeR/reference/gs_fractions_wide.md)
  : Calculate grain-size fraction percentages in wide form
- [`gs_frac_wide()`](https://Gavin987.github.io/grainsizeR/reference/gs_frac_wide.md)
  : Convenience alias for wide grain-size fractions

## Texture polygons and classification

- [`texture_polygon_sources()`](https://Gavin987.github.io/grainsizeR/reference/texture_polygon_sources.md)
  : List planned texture polygon source registries
- [`texture_polygon_template()`](https://Gavin987.github.io/grainsizeR/reference/texture_polygon_template.md)
  : Create an empty texture polygon template
- [`texture_polygon_reconstruction_template()`](https://Gavin987.github.io/grainsizeR/reference/texture_polygon_reconstruction_template.md)
  : Create an empty texture polygon reconstruction template
- [`reconstruction_to_texture_polygons()`](https://Gavin987.github.io/grainsizeR/reference/reconstruction_to_texture_polygons.md)
  : Convert a reconstruction table to texture polygons
- [`validate_texture_polygons()`](https://Gavin987.github.io/grainsizeR/reference/validate_texture_polygons.md)
  : Validate user-supplied texture polygons
- [`classify_texture()`](https://Gavin987.github.io/grainsizeR/reference/classify_texture.md)
  : Classify samples with texture classes
- [`gs_gradistat_sediment_name()`](https://Gavin987.github.io/grainsizeR/reference/gs_gradistat_sediment_name.md)
  : Compose GRADISTAT-style sediment names
- [`ternary_to_xy()`](https://Gavin987.github.io/grainsizeR/reference/ternary_to_xy.md)
  : Convert ternary coordinates to Cartesian coordinates

## Plotting

- [`plot_distribution()`](https://Gavin987.github.io/grainsizeR/reference/plot_distribution.md)
  : Plot retained grain-size distributions
- [`plot_cumulative()`](https://Gavin987.github.io/grainsizeR/reference/plot_cumulative.md)
  : Plot cumulative grain-size curves
- [`plot_fractions()`](https://Gavin987.github.io/grainsizeR/reference/plot_fractions.md)
  : Plot grain-size fraction composition
- [`plot_gradistat_summary()`](https://Gavin987.github.io/grainsizeR/reference/plot_gradistat_summary.md)
  : Plot a GRADISTAT-inspired grain-size summary
- [`plot_texture_triangle()`](https://Gavin987.github.io/grainsizeR/reference/plot_texture_triangle.md)
  : Plot samples on a texture ternary plot
- [`plot_texture_ternary()`](https://Gavin987.github.io/grainsizeR/reference/plot_texture_ternary.md)
  : Preferred alias for texture ternary plots

## Compatibility aliases

- [`gs_percentile()`](https://Gavin987.github.io/grainsizeR/reference/gs_percentile.md)
  : Calculate grain-size percentiles
- [`gs_engineering()`](https://Gavin987.github.io/grainsizeR/reference/gs_engineering.md)
  : Calculate additional grain-size indices
- [`gs_folkward()`](https://Gavin987.github.io/grainsizeR/reference/gs_folkward.md)
  : Calculate Folk and Ward graphical grain-size statistics
- [`gs_diag()`](https://Gavin987.github.io/grainsizeR/reference/gs_diag.md)
  : Convenience alias for grain-size diagnostics
- [`plot_trigon()`](https://Gavin987.github.io/grainsizeR/reference/plot_trigon.md)
  : Plot samples on a ternary diagram
