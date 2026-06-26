# grainsizeR Pre-Release Preparation

## Release Status

This is a pre-release preparation document for a GitHub development
pre-release candidate. The package version remains `0.0.0.9000`. Suggested
future tags include `v0.0.0.9000-rc1` or `v0.1.0-rc1`, but tags should be
created manually only after CI passes.

Repository URL: <https://github.com/Gavin987/grainsizeR>

## Pre-Release Checklist

- Confirm `DESCRIPTION` metadata.
- Regenerate documentation and README.
- Run the full test suite.
- Build the source tarball.
- Run `R CMD check` on the built tarball.
- Confirm GitHub Actions pass.
- Confirm pkgdown builds.
- Review README, NEWS, vignettes, and source-audit notes.

## Verification Commands

```r
devtools::document()
devtools::build_readme()
testthat::test_dir("tests/testthat")
```

```sh
R CMD build .
R CMD check grainsizeR_0.0.0.9000.tar.gz --no-manual
```

## GitHub Actions Checklist

- R CMD check workflow runs on push and pull requests.
- R CMD check workflow covers macOS, Windows, and Ubuntu.
- pkgdown workflow builds on pushes to `main` or `master`.
- Workflows use standard r-lib actions and do not require custom secrets.

## pkgdown Checklist

- Reference sections group preferred user-facing APIs clearly.
- Articles include the basic workflow, method validation, texture polygons, and
  texture source audit.
- Compatibility aliases remain documented but are not emphasized over preferred
  function names.

## License and Provenance Checklist

- Confirm `DESCRIPTION` uses `License: MIT + file LICENSE`.
- Confirm `LICENSE` names Ching-Sung G. Chang as copyright holder.
- Confirm the README explains the MIT license and data provenance policy.
- Confirm official texture polygon datasets are not bundled unless provenance,
  validation, review, and tests are complete.
- Confirm future polygon coordinate datasets are independently reconstructed
  from primary official or academic sources.
- Confirm source manifests and evidence ledgers exist before any future dataset
  is promoted into package data.
- Confirm no `soiltexture` code, class tables, internal data objects, vertex
  tables, polygon coordinates, or internal polygon definitions are copied.

## Versioning and Tag Checklist

- Keep `Version: 0.0.0.9000` for this development pre-release candidate.
- Do not create a tag until local checks and GitHub Actions pass.
- Create release tags manually after review.
- Record any tag and release notes in GitHub Releases.

## Manual Release Steps

1. Confirm the working tree contains only intended changes.
2. Run the verification commands above.
3. Push to GitHub.
4. Wait for R CMD check and pkgdown workflows.
5. Create a GitHub pre-release manually.
6. Attach or reference the checked source tarball if desired.

## First GitHub Push Checklist

These commands are manual first-push steps. They are not run automatically by
the package or by this checklist.

```sh
git remote -v

git remote add origin https://github.com/Gavin987/grainsizeR.git
# or, if origin already exists:
git remote set-url origin https://github.com/Gavin987/grainsizeR.git

git branch -M main
git push -u origin main
```

After pushing:

- Confirm the repository page loads.
- Confirm the README renders correctly on GitHub.
- Confirm GitHub Actions started.
- Confirm the R CMD check workflow passes.
- Confirm the pkgdown workflow passes, or identify any GitHub Pages setup
  required by the repository.
- Confirm installation works from a clean R session:

```r
devtools::install_github("Gavin987/grainsizeR")
library(grainsizeR)
```

## Known Caveats

Local CRAN repository-index access warnings may reflect mirror or network
configuration rather than package logic. Confirm whether any warning is from
package code before treating it as a release blocker.

Built-in official texture polygon datasets are not bundled yet. Source-audit
and reconstruction scaffold files under `data-raw/` are development materials.

## Scope Exclusions

grainsizeR does not implement civil-engineering classification modules. The
package scope remains sedimentology, grain-size statistics, particle-size
fractions, soil texture fractions, texture ternary plots, and
literature-documented soil or sediment texture systems.
