# iOS TestFlight deploy

Reusable workflow `.github/workflows/ios-testflight.yml` archives an app on a `macos-latest` runner and uploads it to TestFlight, signing with the paid team's cloud-managed certificates via an App Store Connect API key.

## Set up an app

Copy `templates/app-ios-testflight.yml` to `.github/workflows/deploy-ios.yml`, replacing `@NAME@` with the scheme. Add repository secrets:

- `ASC_KEY_ID`, `ASC_ISSUER_ID`: from App Store Connect → Users and Access → Integrations. The key needs the App Manager role.
- `ASC_KEY_P8`: the contents of the downloaded `.p8`.

The app record must exist in App Store Connect and `DEVELOPMENT_TEAM` must be set in the project.

## Inputs

- `scheme` (required): scheme to archive.
- `project-dir` (default `ios`): holds `project.yml` (generated with `xcodegen`) or the single `.xcodeproj`.
- `env`: newline-separated `KEY=value` pairs exported before project generation, e.g. variables substituted by `xcodegen`.

The build number is the run number, so every upload is unique. The marketing version comes from the project.
