# CLAUDE.md

Shared reusable workflows, scripts and templates for willsawyerrrr.dev projects. See the parent `CLAUDE.md` for workflow conventions.

- Changes to a reusable workflow affect every app that calls it at `@main`; keep inputs backwards compatible.
- Keep `docs/` in sync with workflows, scripts and templates.
- `templates/` use `@NAME@`-style placeholders and are not valid workflows or formulae until filled.
- `ci.yml` ends with a `CI Status` job that `needs:` every other job in the workflow; add new jobs to its `needs:`. The `main` ruleset requires only `CI Status`.
