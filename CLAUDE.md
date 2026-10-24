# CLAUDE.md

Shared reusable workflows, scripts and templates for willsawyerrrr.dev projects. See the parent `CLAUDE.md` for workflow conventions.

- Changes to a reusable workflow affect every app that calls it at `@main`; keep inputs backwards compatible.
- iOS and macOS jobs pin `macos-26` and Xcode 26.6 (`DEVELOPER_DIR`), the newest GA Xcode on GitHub's runners; never `macos-latest`.
- `scripts/attach-build` runs on Node 26 in CI (`setup-node` in `ios-testflight.yml`) and locally (`.nvmrc`).
- `ios-testflight.yml` fails before archiving unless `MARKETING_VERSION` equals its `marketing-version` input (default `0.1.0`).
- Keep `docs/` in sync with workflows, scripts and templates.
- Secrets come from a 1Password Environment, never `secrets.*`/`vars.*` beyond the `OP_*` bootstrap values: workflows load them with `1password/load-secrets-action` (`export-env: true`) and scripts via `op run --environment "$OP_ENVIRONMENT_ID"`. Keep `docs/1password-environments.md` in sync.
- `templates/` use `@NAME@`-style placeholders and are not valid workflows, formulae or casks until filled.
- `scripts/add-app` handles both formulae and casks (`--cask`); keep the formula and cask paths, their templates and `docs/homebrew-tap.md` in sync.
- `ci.yml` ends with a `CI Status` job that `needs:` every other job in the workflow; add new jobs to its `needs:`. The `main` ruleset requires a pull request (squash merges only) and `CI Status`, and blocks force pushes and deletion.
- `ci.yml` runs pre-commit on Python 3.15, pinned by `.python-version` (the local toolchain).
- `tests/` holds bats tests (`bats tests/`) for `scripts/*` and the templates `add-app` renders; add or update tests with every script change. They stub `gh`, `curl`, `git`, `xcrun` etc. on `PATH` (and `fetch` for `attach-build`) so nothing touches the network. CI runs them in the `test` job.
