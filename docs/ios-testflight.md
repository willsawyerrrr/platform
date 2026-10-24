# iOS TestFlight deploy

Reusable workflow `.github/workflows/ios-testflight.yml` archives an app on a `macos-26` runner with Xcode 26.6 (the newest GA Xcode on GitHub's runners) and uploads it to TestFlight, signing with the paid team's cloud-managed certificates via an App Store Connect API key.

The archive is unsigned (`CODE_SIGNING_ALLOWED=NO`) and uses no API key. The `Embed entitlements` step then ad-hoc signs each bundle in the archive with its target's `CODE_SIGN_ENTITLEMENTS` file, expanding `$(PRODUCT_BUNDLE_IDENTIFIER)`, `$(AppIdentifierPrefix)` and `$(TeamIdentifierPrefix)`, because an unsigned archive carries no entitlements and export signing keeps only those already embedded. Only `xcodebuild -exportArchive` signs with the team's certificate, with `signingStyle: automatic` and `-allowProvisioningUpdates`, so the runner uses the team's one cloud-managed Apple Distribution certificate and an App Store profile. A signed archive under automatic signing needs an Apple Development certificate, which every ephemeral runner would mint anew until the team reached Apple's certificate limit and the archive failed with `Choose a certificate to revoke`.

## Set up an app

Copy `templates/app-ios-testflight.yml` to `.github/workflows/deploy-ios.yml`, replacing `@NAME@` with the scheme. Set up [1Password Environments](1password-environments.md) for the repo, with `OP_ENVIRONMENT_IDS` starting with the shared Apple Development Environment (`b5zkkwxuutlttwbrv5xhgojye4`). It holds these variables:

- `ASC_KEY_ID`, `ASC_ISSUER_ID`: from App Store Connect → Users and Access → Integrations. The key needs the Admin role, which cloud signing requires.
- `ASC_KEY_P8`: the contents of the downloaded `.p8`.

- `DEVELOPMENT_TEAM`: the paid team ID.

The app record must exist in App Store Connect.

## Inputs

- `scheme` (required): scheme to archive.
- `project-dir` (default `ios`): holds `project.yml` (generated with `xcodegen`) or the single `.xcodeproj`.
- `marketing-version` (default `0.1.0`): the `MARKETING_VERSION` the project must declare for the scheme's Release configuration. The `Check the marketing version` step fails the run before archiving otherwise. Internal builds all use `0.1.0`, so an app never has TestFlight groups for both `1.0` and `0.1.0`; set it to e.g. `1.0` to ship that version.
- `env`: newline-separated `KEY=value` pairs exported before project generation, e.g. variables substituted by `xcodegen`.

After the upload, `scripts/attach-build` waits for App Store Connect to process the build, then attaches it to the app's editable App Store version for the marketing version, renaming the editable version if it has another number, or creating the version if none exists; a version that is already in review or released is left as it is. The listing shows a placeholder icon until a build is attached, so this gives it the build's icon. The version is not submitted for review.

The build number is the run number, so every upload is unique. The marketing version comes from the project and must match `marketing-version`.
