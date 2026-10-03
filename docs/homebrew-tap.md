# Homebrew tap

Apps are published to [`willsawyerrrr/homebrew-tap`](https://github.com/willsawyerrrr/homebrew-tap).

## Add an app

1. Cut the app's first release (`gh release create v0.1.0 --generate-notes`).
2. `scripts/add-app <app-repo> "<description>"` scaffolds `Formula/<app>.rb` in the tap and `.github/workflows/release.yml` in the app.
3. Fill in the formula's `install` and `test` blocks; run `brew install --build-from-source` and `brew audit --strict` against it.
4. Give the app repo the tap's deploy key: `gh secret set TAP_DEPLOY_KEY --repo willsawyerrrr/<app> < <key>`.
5. Commit and push the formula (tap) and workflow (app).

## Release a new version

Merge to the app's `main`. The shared `release.yml` workflow tags the next version (minor for a `feat` commit, patch otherwise), publishes a GitHub release, then `homebrew.yml` commits `feat: Update <app> to <tag>` to the tap with the new `url` and `sha256`.

## Workflows

- `release.yml`: reusable. Input `formula` (omit to skip Homebrew). Secret `TAP_DEPLOY_KEY`.
- `homebrew.yml`: reusable. Inputs `tag` and `formula` (default: calling repo's name). Secret `TAP_DEPLOY_KEY`.

Apps call them via `uses: willsawyerrrr/platform/.github/workflows/release.yml@main`; this repo's Actions access is set to "Accessible from repositories owned by the user".
