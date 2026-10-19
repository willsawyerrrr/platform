# CLAUDE.md

Shared reusable workflows, scripts and templates for willsawyerrrr.dev projects. See the parent `CLAUDE.md` for workflow conventions.

- Changes to a reusable workflow affect every app that calls it at `@main`; keep inputs backwards compatible.
<<<<<<< HEAD
- iOS and macOS jobs pin `macos-26` and Xcode 26.6 (`DEVELOPER_DIR`), the newest GA Xcode on GitHub's runners; never `macos-latest`.
=======
- `scripts/attach-build` runs on Node 26 in CI (`setup-node` in `ios-testflight.yml`) and locally (`.nvmrc`).
>>>>>>> 8697e0b (ci: Pin Node 26 for the App Store Connect build-attach script)
- Keep `docs/` in sync with workflows, scripts and templates.
- `templates/` use `@NAME@`-style placeholders and are not valid workflows, formulae or casks until filled.
- `scripts/add-app` handles both formulae and casks (`--cask`); keep the formula and cask paths, their templates and `docs/homebrew-tap.md` in sync.
- `ci.yml` ends with a `CI Status` job that `needs:` every other job in the workflow; add new jobs to its `needs:`. The `main` ruleset requires a pull request (squash merges only) and `CI Status`, and blocks force pushes and deletion.
