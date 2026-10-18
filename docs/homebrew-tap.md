# Homebrew tap

Apps are published to [`willsawyerrrr/homebrew-tap`](https://github.com/willsawyerrrr/homebrew-tap).

## Add an app (formula)

1. Cut the app's first release (`gh release create v0.1.0 --generate-notes`).
2. `scripts/add-app <app-repo> "<description>"` scaffolds `Formula/<app>.rb` in the tap and `.github/workflows/release.yml` in the app.
3. Fill in the formula's `install` and `test` blocks; run `brew install --build-from-source` and `brew audit --strict` against it.
4. Give the app repo the tap's deploy key: `gh secret set TAP_DEPLOY_KEY --repo willsawyerrrr/<app> < <key>`.
5. Commit and push the formula (tap) and workflow (app).

### Add a cask app

1. `scripts/add-app --cask <app-repo> "<description>"` scaffolds `Casks/<app>.rb` in the tap (and a row in the tap's README table) and a cask `.github/workflows/release.yml` in the app. The bundle is `<App>.app` in `<App>.zip`, where `<App>` is the repo name in PascalCase; override with `APP_BUNDLE`.
2. Replace the workflow's `build-command` with the app's packaging command (it must produce `<App>.zip` at the repo root) and adjust the cask's `zap` stanza and `depends_on macos:`. Add `binary` stanzas if the app ships a CLI.
3. No release is needed first: the cask starts at the latest release if it has the zip, else at `0.0.0` with a zero checksum that the first release replaces.
4. Give the app repo the tap's deploy key, as above, and any signing secrets (see Casks).
5. Run `brew style --fix` and `brew audit --cask --online <app>` in the tap, then commit and push the cask (tap) and workflow (app). The online audit needs the first release's zip, so it only passes once that release exists; the tap's CI runs the same checks.

## Release a new version

Merge to the app's `main`. The shared `release.yml` workflow tags the next version (minor for a `feat` commit, patch otherwise), publishes a GitHub release, then `homebrew.yml` commits `feat: Update <app> to <tag>` to the tap with the new `url` and `sha256`.

## Workflows

- `release.yml`: reusable. Inputs: `formula` or `cask` (mutually exclusive; omit both to skip Homebrew), and, with `cask`, `build-command` and `asset`. Secrets `TAP_DEPLOY_KEY` and, for signing, `DEVELOPER_ID_P12`, `DEVELOPER_ID_P12_PASSWORD`, `NOTARY_KEY`, `NOTARY_KEY_ID`, `NOTARY_ISSUER_ID`.
- `homebrew.yml`: reusable. Inputs: `tag`; `formula` (default: calling repo's name) or `cask`; `asset` (with `cask`). Secret `TAP_DEPLOY_KEY`.

## Casks

An app can ship as a cask from a prebuilt macOS zip. Set `cask` (the token in `Casks/<cask>.rb`), `build-command` and `asset` in `release.yml`.

- The release is created as a draft. A macOS job checks out the released commit, runs `build-command` at the repo root with `VERSION` set to the tag without `v`, and uploads `asset` to the draft under its basename, then publishes the release, which creates the tag.
- `build-command` must produce `asset`, e.g. with `ditto -c -k --keepParent`.
- Signing: with `DEVELOPER_ID_P12` (base64 `.p12`) and `DEVELOPER_ID_P12_PASSWORD`, the job imports the certificate into a temporary keychain and sets `SIGNING_IDENTITY` (`Developer ID Application: …`) for `build-command`. With `NOTARY_KEY` (base64 App Store Connect `.p8`), `NOTARY_KEY_ID` and `NOTARY_ISSUER_ID`, it also sets `NOTARY_KEY_PATH`, `NOTARY_KEY_ID` and `NOTARY_ISSUER_ID`, e.g. for `xcrun notarytool submit --key "$NOTARY_KEY_PATH" --key-id "$NOTARY_KEY_ID" --issuer "$NOTARY_ISSUER_ID"`. The keychain and key are deleted after the job. Without the secrets nothing is set, and `build-command` should sign ad hoc.
- `homebrew.yml` sets `version` and `sha256` in `Casks/<cask>.rb` (the asset's checksum) and commits `feat: Update <cask> to <tag>`. The cask's `url` must use `#{version}`.

Apps call them via `uses: willsawyerrrr/platform/.github/workflows/release.yml@main`. This repo must stay public for other repos to call its workflows.
