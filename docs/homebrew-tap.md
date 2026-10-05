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

- `release.yml`: reusable. Inputs: `formula` or `cask` (mutually exclusive; omit both to skip Homebrew), and, with `cask`, `build-command` and `asset`. Secret `TAP_DEPLOY_KEY`.
- `homebrew.yml`: reusable. Inputs: `tag`; `formula` (default: calling repo's name) or `cask`; `asset` (with `cask`). Secret `TAP_DEPLOY_KEY`.

## Casks

An app can ship as a cask from a prebuilt macOS zip. Set `cask` (the token in `Casks/<cask>.rb`), `build-command` and `asset` in `release.yml`.

- The release is created as a draft. A macOS job checks out the released commit, runs `build-command` at the repo root with `VERSION` set to the tag without `v`, and uploads `asset` to the draft under its basename, then publishes the release, which creates the tag.
- `build-command` must produce `asset`, e.g. with `ditto -c -k --keepParent`.
- `homebrew.yml` sets `version` and `sha256` in `Casks/<cask>.rb` (the asset's checksum) and commits `feat: Update <cask> to <tag>`. The cask's `url` must use `#{version}`.

Apps call them via `uses: willsawyerrrr/platform/.github/workflows/release.yml@main`. This repo must stay public for other repos to call its workflows.
