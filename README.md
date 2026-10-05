# platform

Engineering platform shared by all willsawyerrrr.dev projects.

- [Homebrew tap](docs/homebrew-tap.md): add apps to the tap and release new versions.
- [iOS device deploy](docs/ios-device-deploy.md): keep an app installed on the paired iPhone.
- [iOS TestFlight deploy](docs/ios-testflight.md): ship an app to TestFlight from GitHub Actions.

## Reusable workflows

Called from apps as `willsawyerrrr/platform/.github/workflows/<name>@main`.

- `release.yml`: tag the next version and publish a GitHub release, optionally building a cask asset and updating the tap.
- `homebrew.yml`: point a tap formula or cask at a release.
- `ios-testflight.yml`: archive an iOS app and upload it to TestFlight.

## Scripts

- `scripts/add-app`: add an app to the Homebrew tap and wire its release workflow.
- `scripts/deploy-to-device`: build and install an iOS app on the paired iPhone.
- `scripts/deploy-main-to-device`: fast-forward an app's `main`, then deploy it.
- `scripts/install-deploy-agent`: schedule `deploy-main-to-device` with launchd.

## Templates

`templates/` holds the files `scripts/add-app` and the docs copy into apps and the tap. Placeholders such as `@NAME@` are substituted when used.
