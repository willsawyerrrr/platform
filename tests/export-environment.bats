# shellcheck disable=SC2016  # stub bodies are deliberately single-quoted
setup() {
  load test_helper
  setup_sandbox
  SCRIPT="$ROOT/.github/actions/load-op-environment/export-environment"
  export GITHUB_ENV="$SANDBOX/github-env"
  : > "$GITHUB_ENV"
  export OP_SERVICE_ACCOUNT_TOKEN=ops_token
  export OP_ENVIRONMENTS="env-a env-b"
  # Stub `op run [--no-masking] --environment <id>... -- cmd`: runs `cmd` with each
  # Environment's variables, later Environments overriding earlier ones.
  stub op '
    shift
    envs=()
    while [[ "$1" != -- ]]; do
      case "$1" in
        --environment)
          case "$2" in
            env-a) envs+=(UNIQUE_A=a SAME=a "MULTI=line1
line2") ;;
            env-b) envs+=(UNIQUE_B=b SAME=b) ;;
          esac
          shift ;;
      esac
      shift
    done
    shift
    exec env "${envs[@]}" "$@"'
}

@test "exports variables from every Environment, last winning" {
  run "$SCRIPT"
  assert_success
  assert_output --partial '::add-mask::b'
  assert_output --partial '::add-mask::line1'
  assert_output --partial '::add-mask::line2'
  run grep -c '<<' "$GITHUB_ENV"
  assert_output 4
  run sed -n '/^SAME</,/^ghadelimiter/p' "$GITHUB_ENV"
  assert_line --index 1 b
  run grep -A3 '^MULTI<<' "$GITHUB_ENV"
  assert_line --index 1 line1
  assert_line --index 2 line2
}

@test "honours the order of the Environments" {
  OP_ENVIRONMENTS="env-b env-a" run "$SCRIPT"
  assert_success
  run sed -n '/^SAME</,/^ghadelimiter/p' "$GITHUB_ENV"
  assert_line --index 1 a
}

@test "separates Environment IDs by any whitespace" {
  OP_ENVIRONMENTS=$'env-a\n  env-b' run "$SCRIPT"
  assert_success
  run grep -c '^UNIQUE_[AB]<<' "$GITHUB_ENV"
  assert_output 2
  assert_equal "$(cat "$CALLS")" 'op run --no-masking --environment env-a --environment env-b -- env -0'
}

@test "skips variables the shell already has with the same value" {
  SAME=b run "$SCRIPT"
  assert_success
  run grep -c '^SAME<<' "$GITHUB_ENV"
  assert_output 0
}

@test "exports variables whose value changed" {
  SAME=old run "$SCRIPT"
  assert_success
  run grep -c '^SAME<<' "$GITHUB_ENV"
  assert_output 1
}

@test "never exports the service account token" {
  run "$SCRIPT"
  assert_success
  run grep -c 'ops_token\|OP_SERVICE_ACCOUNT_TOKEN' "$GITHUB_ENV"
  assert_output 0
  refute_output --partial ops_token
}

@test "fails without a token" {
  unset OP_SERVICE_ACCOUNT_TOKEN
  run "$SCRIPT"
  assert_failure
  assert_output --partial '::error::service-account-token is empty'
  assert_equal "$(cat "$CALLS")" ''
}

@test "fails without Environment IDs" {
  OP_ENVIRONMENTS=$' \n' run "$SCRIPT"
  assert_failure
  assert_output --partial '::error::environments is empty'
  assert_equal "$(cat "$CALLS")" ''
}
