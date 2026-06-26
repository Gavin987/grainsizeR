# Contributing to grainsizeR

Thank you for considering a contribution to grainsizeR. The project focuses on
R-native sediment grain-size analysis, GRADISTAT/G2Sd-style workflows, and USDA
and GRADISTAT texture workflows.

## Reporting Bugs

Open a GitHub issue and include:

- the grainsizeR version,
- your R version and operating system,
- a minimal reproducible example,
- the input data shape and units,
- the full error or warning message.

Small example datasets are preferred. Do not upload confidential data.

## Requesting Features

Feature requests should describe the workflow need, expected API, and source
method reference. Scientific method requests need primary academic or official
references. Requests for new texture systems should include provenance for any
polygon boundaries or decision rules.

## Example Data

Example data should be small, non-confidential, and arranged as retained
grain-size classes in long or wide form. Include units and whether values are
percent, proportion, count, or mass.

## Documentation and Terminology

All roxygen comments, exported documentation, examples, vignettes, README text,
NEWS entries, tests, and developer-facing comments must be written in English.
Use `ternary plot` as the formal plotting term. The compatibility function
`plot_texture_triangle()` remains available, but new examples should prefer
`plot_texture_ternary()`.

Use `GRADISTAT` and `G2Sd` with this exact capitalization in prose.

## Scope Boundaries

Current scope includes sediment grain-size summaries, GRADISTAT/G2Sd-style
functional replacement workflows, USDA major texture classification,
GRADISTAT texture classification, sediment-name composition, and texture
ternary plots.

AASHTO and USCS civil-engineering classification modules are outside the
current release scope unless accepted in a future design decision. USDA
sand-size modifier subclasses are deferred.

## Pull Requests

Before opening a pull request, run the relevant tests. For documentation or API
changes, run:

```r
devtools::document()
devtools::build_readme()
devtools::load_all()
testthat::test_dir("tests/testthat")
```

For release-facing changes, also build vignettes and run `R CMD check` locally
when feasible.
