# 1Password Environments

Secrets for CI and local development live in a [1Password Environment](https://developer.1password.com/docs/environments/); nothing is stored as a GitHub secret except the service account token that unlocks it.

## CI

Reusable workflows load the Environments with the composite action `.github/actions/load-op-environment`, which authenticates the 1Password CLI with a [service account](https://developer.1password.com/docs/service-accounts/) and runs `op run --environment` (macOS and Linux runners only). Every variable the Environments define is masked and exported to later steps in the job. The token itself is not exported.

```yaml
- uses: willsawyerrrr/platform/.github/actions/load-op-environment@main
  with:
    service-account-token: ${{ secrets.OP_SERVICE_ACCOUNT_TOKEN }}
    environments: ${{ vars.OP_ENVIRONMENT_IDS }}
```

`environments` is a whitespace-separated list of Environment IDs, the shared Apple Development Environment (`b5zkkwxuutlttwbrv5xhgojye4`) first and the project's last (`OP_ENVIRONMENT_IDS` = `b5zkkwxuutlttwbrv5xhgojye4 <project-id>`). When several Environments define the same variable, the last one listed wins.

Per calling repo:

- A service account, created at 1Password.com → Developer → Directory → Other → Create a Service Account. Choose its Environments at creation; access is read-only and cannot be changed afterwards. Use one service account per repo, scoped to that repo's Environments.
- Secret `OP_SERVICE_ACCOUNT_TOKEN`: the service account's token.
- Variable `OP_ENVIRONMENT_IDS`: one or more Environment IDs, in precedence order. Set it to the Apple Development ID first and the project's ID last, e.g. `b5zkkwxuutlttwbrv5xhgojye4 <project-id>`; an app with no Environment of its own sets just `b5zkkwxuutlttwbrv5xhgojye4`.
- The Environments hold the variables the workflows use. `ASC_KEY_ID`, `ASC_ISSUER_ID`, `ASC_KEY_P8` and `DEVELOPMENT_TEAM` live only in the shared Apple Development Environment (`b5zkkwxuutlttwbrv5xhgojye4`); the Platform Environment (`3wm7pn2k5bnmyuzqznz33lufp4`) holds `TAP_DEPLOY_KEY`, `RECRAFT_API_KEY`, `DEVELOPER_ID_P12`, `DEVELOPER_ID_P12_PASSWORD`, `NOTARY_KEY`, `NOTARY_KEY_ID` and `NOTARY_ISSUER_ID`. Platform's own workflows load no Environment.

| Workflow | Variables |
| --- | --- |
| `ios-testflight.yml` | `ASC_KEY_ID`, `ASC_ISSUER_ID`, `ASC_KEY_P8`, `DEVELOPMENT_TEAM` (all from Apple Development) |
| `release.yml` (cask signing, all optional) | `DEVELOPER_ID_P12`, `DEVELOPER_ID_P12_PASSWORD`, `NOTARY_KEY`, `NOTARY_KEY_ID`, `NOTARY_ISSUER_ID` |
| `homebrew.yml` | `TAP_DEPLOY_KEY` (from the project or Platform Environment) |
| `scripts/generate-logo` (local) | `RECRAFT_API_KEY` |

## Local development

Run commands under `op run` so the Environment's variables are set for the command only:

```sh
op run --environment "$OP_ENVIRONMENT_ID" -- <command>
```

Repeat `--environment` to merge several Environments; the last wins on duplicate names. Platform's Environment is `3wm7pn2k5bnmyuzqznz33lufp4`; the shared Apple Development Environment is `b5zkkwxuutlttwbrv5xhgojye4`.

Set `OP_ENVIRONMENT_ID` in your shell. Copy the ID from the 1Password app → Developer → View Environments → Manage environment → Copy environment ID. `scripts/generate-logo` runs itself under `op run` when `RECRAFT_API_KEY` is unset and `OP_ENVIRONMENT_ID` is set.
