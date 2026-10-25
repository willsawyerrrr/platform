# Generate app logos

`scripts/generate-logo` generates an app logo with the [Recraft](https://www.recraft.ai/pricing?tab=api) image-generation API.

```sh
scripts/generate-logo [--svg] [--out <dir>] <app-name> "<description>"
```

- Writes `<dir>/<app-name>.png` (1024x1024), or `.svg` with `--svg`.
- Needs `jq` and `RECRAFT_API_KEY`, taken from the environment or, when unset, loaded from the Shared 1Password Environment (`3i642eynjpsx2uctyqlexobgge`) via `op run --environment`. See [1Password Environments](1password-environments.md).
- Costs about $0.04 per PNG and $0.08 per SVG.
- From another project, run it by path: `~/willsawyerrrr.dev/platform/main/scripts/generate-logo`.
