# 1Password Environments

Secrets for CI and local development live in a [1Password Environment](https://developer.1password.com/docs/environments/); nothing is stored as a GitHub secret except the key that unlocks it.

## CI

Reusable workflows load the Environment with `1password/load-secrets-action@v5` (`export-env: true`) using Workload Identity (public preview, macOS and Linux runners only). Each job that loads secrets sets:

```yaml
permissions:
  contents: read
  id-token: write
env:
  OP_WORKLOAD_ID: ${{ vars.OP_WORKLOAD_ID }}
  OP_ENVIRONMENT_ID: ${{ vars.OP_ENVIRONMENT_ID }}
  OP_INTEGRATION_KEY: ${{ secrets.OP_INTEGRATION_KEY }}
```

Every variable in the Environment is exported to later steps in the job.

Per calling repo:

- Variables `OP_WORKLOAD_ID` and `OP_ENVIRONMENT_ID`, and secret `OP_INTEGRATION_KEY`.
- The calling workflow grants `id-token: write` (the app templates do), which the reusable workflow needs to request the OIDC token.
- The Environment holds the variables the workflows use:

| Workflow | Variables |
| --- | --- |
| `ios-testflight.yml` | `ASC_KEY_ID`, `ASC_ISSUER_ID`, `ASC_KEY_P8`; optionally `DEVELOPMENT_TEAM` |
| `release.yml` (cask signing, all optional) | `DEVELOPER_ID_P12`, `DEVELOPER_ID_P12_PASSWORD`, `NOTARY_KEY`, `NOTARY_KEY_ID`, `NOTARY_ISSUER_ID` |
| `homebrew.yml` | `TAP_DEPLOY_KEY` |
| `scripts/generate-logo` (local) | `RECRAFT_API_KEY` |

## Local development

Run commands under `op run` so the Environment's variables are set for the command only:

```sh
op run --environment "$OP_ENVIRONMENT_ID" -- <command>
```

Set `OP_ENVIRONMENT_ID` in your shell. Copy the ID from the 1Password app → Developer → View Environments → Manage environment → Copy environment ID. `scripts/generate-logo` runs itself under `op run` when `RECRAFT_API_KEY` is unset and `OP_ENVIRONMENT_ID` is set.
