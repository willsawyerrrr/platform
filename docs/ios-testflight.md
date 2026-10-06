# iOS TestFlight deploy

Reusable workflow `.github/workflows/ios-testflight.yml` archives an app on a `macos-latest` runner and uploads it to TestFlight, signing with the paid team's cloud-managed certificates via an App Store Connect API key.

The archive is unsigned (`CODE_SIGNING_ALLOWED=NO`) and uses no API key. Only `xcodebuild -exportArchive` signs, with `signingStyle: automatic` and `-allowProvisioningUpdates`, so the runner uses the team's one cloud-managed Apple Distribution certificate and an App Store profile. A signed archive under automatic signing needs an Apple Development certificate, which every ephemeral runner would mint anew until the team reached Apple's certificate limit and the archive failed with `Choose a certificate to revoke`.

## Set up an app

Copy `templates/app-ios-testflight.yml` to `.github/workflows/deploy-ios.yml`, replacing `@NAME@` with the scheme. Add repository secrets:

- `ASC_KEY_ID`, `ASC_ISSUER_ID`: from App Store Connect → Users and Access → Integrations. The key needs the Admin role, which cloud signing requires.
- `ASC_KEY_P8`: the contents of the downloaded `.p8`.

The app record must exist in App Store Connect and the signing team must be set, either as `DEVELOPMENT_TEAM` in the project or via the `env` input (see below).

## Inputs

- `scheme` (required): scheme to archive.
- `project-dir` (default `ios`): holds `project.yml` (generated with `xcodegen`) or the single `.xcodeproj`.
- `env`: newline-separated `KEY=value` pairs exported before project generation, e.g. variables substituted by `xcodegen`.
  - `DEVELOPMENT_TEAM`: when non-empty, passed to `xcodebuild archive` as a build setting and to the export options as `teamID`, keeping the team ID out of the repo. Omit it when the project sets the team.

```yaml
with:
  env: |
    DEVELOPMENT_TEAM=${{ vars.DEVELOPMENT_TEAM }}
```

The build number is the run number, so every upload is unique. The marketing version comes from the project.
