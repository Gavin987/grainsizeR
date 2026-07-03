# Release Notes / Release Workflow

## Current status

- Current package version: 0.2.0
- Pending GitHub release: v0.2.0
- Previous GitHub release: v0.1.0
- Zenodo DOI: pending GitHub Release and Zenodo archive
- CRAN submission: deferred

## Post-v0.1.0 hardening

Post-v0.1.0 hardening is complete for the v0.2.0 release readiness pass.
The v0.2.0 GitHub Release and Zenodo archive are still pending. CRAN is
deferred.

## Guardrails

- Do not retag v0.1.0.
- Do not force-push release tags.
- Do not create Zenodo DOI until the v0.2.0 GitHub Release is published and
  archived.
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
