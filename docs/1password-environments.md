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

`environments` is a whitespace-separated list of Environment IDs: shared Environments first, the project's own last. When several Environments define the same variable, the last one listed wins.

Shared Environments:

- Apple Development (`b5zkkwxuutlttwbrv5xhgojye4`): `DEVELOPMENT_TEAM`, `ASC_KEY_ID`, `ASC_ISSUER_ID`, `ASC_KEY_P8`, `DEVELOPER_ID_P12`, `DEVELOPER_ID_P12_PASSWORD`, `NOTARY_KEY`, `NOTARY_KEY_ID`, `NOTARY_ISSUER_ID`.
- General Purpose (`3i642eynjpsx2uctyqlexobgge`): `SUPABASE_ACCESS_TOKEN`, `SUPABASE_PAT`, `VERCEL_TOKEN`, `GITHUB_TOKEN`, `LINEAR_API_KEY`, `VAPI_API_KEY`, `TWILIO_ACCOUNT_SID`, `TWILIO_AUTH_TOKEN`, `RECRAFT_API_KEY`, `RESEND_API_KEY`, `DIGITALOCEAN_TOKEN`, `HF_TOKEN`, `TAILSCALE_AUTHKEY`, `TAP_DEPLOY_KEY`.

Per calling repo:

- A service account, created at 1Password.com → Developer → Directory → Other → Create a Service Account. Choose its Environments at creation; access is read-only and cannot be changed afterwards. Use one service account per repo, scoped to the Environments listed in `OP_ENVIRONMENT_IDS`.
- Secret `OP_SERVICE_ACCOUNT_TOKEN`: the service account's token.
- Variable `OP_ENVIRONMENT_IDS`: every Environment the repo's workflows need, in precedence order, e.g. `b5zkkwxuutlttwbrv5xhgojye4 3i642eynjpsx2uctyqlexobgge <project-id>`. An iOS app needs Apple Development; a Homebrew formula needs General Purpose; a signed cask needs both.

Platform's own workflows load no Environment.

| Workflow | Variables |
| --- | --- |
| `ios-testflight.yml` | `ASC_KEY_ID`, `ASC_ISSUER_ID`, `ASC_KEY_P8`, `DEVELOPMENT_TEAM` (Apple Development) |
| `release.yml` (cask signing, all optional) | `DEVELOPER_ID_P12`, `DEVELOPER_ID_P12_PASSWORD`, `NOTARY_KEY`, `NOTARY_KEY_ID`, `NOTARY_ISSUER_ID` (Apple Development) |
| `homebrew.yml` | `TAP_DEPLOY_KEY` (General Purpose) |
| `scripts/generate-logo` (local) | `RECRAFT_API_KEY` (General Purpose) |

## Local development

Run commands under `op run` so the Environments' variables are set for the command only:

```sh
op run --environment <environment-id> -- <command>
```

Repeat `--environment` to merge several Environments; the last wins on duplicate names. Copy an ID from the 1Password app → Developer → View Environments → Manage environment → Copy environment ID. `scripts/generate-logo` runs itself under `op run` with General Purpose (`3i642eynjpsx2uctyqlexobgge`) when `RECRAFT_API_KEY` is unset and the 1Password CLI is installed.
