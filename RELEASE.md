# Release Notes / Release Workflow

## Current status

- Latest GitHub release: v0.1.0
- Current development version: 0.1.0.9000
- Zenodo DOI: deferred
- CRAN submission: deferred

## Post-v0.1.0 hardening

Before Zenodo archiving, complete:

1. Performance and complexity review.
2. Full workflow verification from bundled examples.
3. Variable and argument naming review.
4. User-facing error-message review.
5. Documentation and vignette polish.
6. Review for overly AI-like code or documentation patterns.
7. Final package checks and GitHub Actions verification.

## Guardrails

- Do not retag v0.1.0.
- Do not force-push release tags.
- Do not create Zenodo DOI until the hardening phase is complete.
- Do not prepare CRAN submission material until CRAN submission is planned.

## First GitHub Push Checklist

Historical first-push commands are retained here for repository metadata
checks only. The repository already exists at
<https://github.com/Gavin987/grainsizeR>.

```sh
git remote add origin https://github.com/Gavin987/grainsizeR.git
# or, if origin already exists:
git remote set-url origin https://github.com/Gavin987/grainsizeR.git
```

Clean install check:

```r
devtools::install_github("Gavin987/grainsizeR")
```
