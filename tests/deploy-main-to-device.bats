# shellcheck disable=SC2016  # stub bodies are deliberately single-quoted
setup() {
  load test_helper
  setup_sandbox
  mkdir "$SANDBOX/scripts"
  cp "$ROOT/scripts/deploy-main-to-device" "$SANDBOX/scripts/"
  printf '#!/usr/bin/env bash\necho "deploy-to-device $*" >> "$CALLS"\n' > "$SANDBOX/scripts/deploy-to-device"
  chmod +x "$SANDBOX/scripts/deploy-to-device"
  stub git '[[ -z "${GIT_FAIL:-}" ]] || exit 1'
}

@test "requires --repo" {
  run "$SANDBOX/scripts/deploy-main-to-device" --name app
  assert_failure 2
  assert_output --partial 'usage: deploy-main-to-device'
}

@test "fast-forwards the repo then deploys with all flags" {
  run "$SANDBOX/scripts/deploy-main-to-device" --name app --repo /r --force
  assert_success
  assert_equal "$(cat "$CALLS")" "git -C /r pull --ff-only --quiet
deploy-to-device --name app --repo /r --force"
}

@test "does not deploy when the fast-forward fails" {
  GIT_FAIL=1 run "$SANDBOX/scripts/deploy-main-to-device" --name app --repo /r
  assert_failure
  run grep deploy-to-device "$CALLS"
  assert_failure
}
