# Xcode build cache

Composite action `.github/actions/xcode-cache` caches `~/Library/Developer/Xcode/DerivedData`, which holds the resolved Swift packages (`SourcePackages`) and every build product, so a job skips cloning packages and rebuilding unchanged ones. Index data and logs are left out.

```yaml
- uses: actions/checkout@v7
- uses: willsawyerrrr/platform/.github/actions/xcode-cache@main
```

Add it to every Xcode job, after checkout and before the first `xcodebuild`. `ios-testflight.yml` already does. xcodebuild must use the default DerivedData location (no `-derivedDataPath`).

The key is the selected Xcode's build version, the `key` input (default: the job ID) and the hash of every `project.yml`, `Package.swift` and `Package.resolved`. Changing any of them saves a new cache; otherwise the job restores the newest cache for the same Xcode and `key`. Give jobs in one workflow that build different schemes or destinations under the same job ID distinct `key`s.

Sources checked out by `actions/checkout` are newer than the restored products, so the app's own targets always rebuild; packages, whose checkouts are restored with the cache, do not.
