# Release Notes / Release Workflow

## Current status

- Latest GitHub release: v0.2.0
- Current package version: 0.3.0
- Pending release: v0.3.0
- Latest published release before this: v0.2.0
- GitHub Release for v0.3.0: pending
- Zenodo archive/DOI for v0.3.0: pending GitHub Release
- Zenodo Concept DOI: 10.5281/zenodo.21169393
- Latest published Zenodo Version DOI: 10.5281/zenodo.21169394 (v0.2.0)
- CRAN submission: deferred

## Post-v0.2.0 hardening and performance work

Post-v0.2.0 correctness, test-hygiene, and performance work is complete for
the v0.3.0 release-preparation pass. This includes deterministic percentile
tie-breaking, the below-boundary fraction/percent-finer fix, nominal sieve-mesh
equivalence handling for 0.0625 mm / 0.063 mm, Krumbein quartile deviation
output, `gs_parameters()` performance refactors through Stage 3, and expected
test-warning cleanup. The v0.3.0 GitHub Release and Zenodo archive are still
pending. CRAN remains deferred unless separately planned.

## Guardrails

- Do not retag v0.1.0.
- Do not retag v0.2.0.
- Do not force-push release tags.
- Do not rewrite or replace the v0.2.0 GitHub Release, tag, or Zenodo archive.
- Do not say a v0.3.0 Zenodo DOI exists until the GitHub Release has been
  created and archived by Zenodo.
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
