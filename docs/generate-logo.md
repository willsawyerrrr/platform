# Generate app logos

`scripts/generate-logo` generates an app logo with the [Recraft](https://www.recraft.ai/pricing?tab=api) image-generation API.

```sh
scripts/generate-logo [--svg] [--out <dir>] <app-name> "<description>"
```

- Writes `<dir>/<app-name>.png` (1024x1024), or `.svg` with `--svg`.
- Needs `jq` and `RECRAFT_API_KEY`, taken from the environment or `$ENV_FILE` (default `~/willsawyerrrr.dev/.env`).
- Costs about $0.04 per PNG and $0.08 per SVG.
- The `generate-logo` Claude skill in `.claude/skills/` wraps the script.
