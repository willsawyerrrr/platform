# shellcheck disable=SC2016  # stub bodies are deliberately single-quoted
setup() {
  load test_helper
  setup_sandbox
  export RECRAFT_API_KEY=key-from-env
  stub curl '
    out=""; while [[ $# -gt 0 ]]; do [[ "$1" != -o ]] || out="$2"; shift; done
    if [[ -n "${CURL_FAIL:-}" ]]; then exit 22; fi
    if [[ -n "$out" ]]; then echo image > "$out"; else echo "{\"data\":[{\"url\":\"https://cdn.example/logo\"}]}"; fi'
}

@test "requires a name and a description" {
  run "$ROOT/scripts/generate-logo" my-app
  assert_failure
  assert_output --partial 'usage: generate-logo'
}

@test "rejects unknown flags" {
  run "$ROOT/scripts/generate-logo" --bogus my-app "A logo"
  assert_failure
  assert_output --partial 'usage: generate-logo'
}

@test "fails without an API key" {
  unset RECRAFT_API_KEY
  PATH="$BATS_TEST_TMPDIR/empty:$(dirname "$(command -v bash)")"
  run "$ROOT/scripts/generate-logo" my-app "A logo"
  assert_failure
  assert_output --partial 'RECRAFT_API_KEY is not set'
  assert_equal "$(cat "$CALLS")" ''
}

@test "writes a PNG using the raster model" {
  run "$ROOT/scripts/generate-logo" --out "$SANDBOX/out" my-app "A fox"
  assert_success
  assert_output "Wrote $SANDBOX/out/my-app.png"
  assert_equal "$(cat "$SANDBOX/out/my-app.png")" image
  run cat "$CALLS"
  assert_line --partial 'Authorization: Bearer key-from-env'
  assert_line --partial '"model": "recraftv4",'
  assert_line --partial 'A fox'
}

@test "--svg writes an SVG using the vector model" {
  run "$ROOT/scripts/generate-logo" --svg --out "$SANDBOX/out" my-app "A fox"
  assert_success
  assert_output "Wrote $SANDBOX/out/my-app.svg"
  run cat "$CALLS"
  assert_line --partial '"model": "recraftv4_vector"'
}

@test "loads the API key from the 1Password Environment" {
  unset RECRAFT_API_KEY
  stub op 'shift 3; RECRAFT_API_KEY=key-from-op exec "$@"'
  run "$ROOT/scripts/generate-logo" --out "$SANDBOX/out" my-app "A fox"
  assert_success
  run cat "$CALLS"
  assert_line --partial 'op run --environment 3i642eynjpsx2uctyqlexobgge -- '
  assert_line --partial 'Bearer key-from-op'
}

@test "fails when the API call fails" {
  CURL_FAIL=1 run "$ROOT/scripts/generate-logo" --out "$SANDBOX/out" my-app "A fox"
  assert_failure
  assert_not_exist "$SANDBOX/out/my-app.png"
}
