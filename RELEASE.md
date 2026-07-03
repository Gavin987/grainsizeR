# Release Notes / Release Workflow

## Current status

- Latest GitHub release: v0.1.0
- Current development version: 0.1.0.9000
- Zenodo DOI: deferred
- CRAN submission: deferred

## Post-v0.1.0 hardening

Before Zenodo archiving, complete:

1. Performance and complexity review. **Done** — see the Performance Phase
   Round 1 entry in `dev-notes/AUDIT_LOG.md`.
2. Full workflow verification from bundled examples. In progress —
   ad hoc verification passes done so far; no single dedicated pass has
   covered every function in `dev-notes/HARDENING_ROADMAP.md`'s Phase 2 list.
3. Variable and argument naming review. Partially done — the
   `gravel_sand_mud`/`wentworth_major` boundary split and a um/micrometre
   consistency audit are complete; a full pass has not been done.
4. User-facing error-message review. Partially done via the um/micrometre audit;
   not a dedicated pass.
5. Documentation and vignette polish. In progress — a light editorial pass
   for repetitive phrasing has been done; not exhaustive.
6. Review for overly AI-like code or documentation patterns. In progress,
   same pass as item 5.
7. Final package checks and GitHub Actions verification. Not done — local
   `R CMD check` has been run repeatedly, but GitHub Actions has not been
   independently confirmed from this environment.

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
