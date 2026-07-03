# Release Notes / Release Workflow

## Current status

- Latest GitHub release: v0.2.0
- Current development version: 0.2.0.9000
- Previous GitHub release: v0.1.0
- Zenodo archive: complete
- Zenodo Concept DOI: 10.5281/zenodo.21169393
- Zenodo Version DOI: 10.5281/zenodo.21169394
- CRAN submission: deferred

## Post-v0.1.0 hardening

Post-v0.1.0 hardening is complete for the v0.2.0 release readiness pass.
The v0.2.0 GitHub Release and Zenodo archive are complete. CRAN is deferred.

## Guardrails

- Do not retag v0.1.0.
- Do not force-push release tags.
- Do not rewrite or replace the v0.2.0 GitHub Release, tag, or Zenodo archive.
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
