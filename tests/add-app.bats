# shellcheck disable=SC2016  # stub bodies are deliberately single-quoted
setup() {
  load test_helper
  setup_sandbox
  export TAP_DIR="$SANDBOX/tap" APP_DIR="$SANDBOX/app"
  stub gh 'if [[ -n "${GH_TAG:-}" ]]; then echo "$GH_TAG"; else exit 1; fi'
  stub curl 'if [[ -n "${CURL_FAIL:-}" ]]; then exit 22; fi; echo "release-bytes"'
  export GH_TAG=v1.2.3
  sha="$(sha256_of release-bytes)"
}

@test "requires an app and a description" {
  run "$ROOT/scripts/add-app"
  assert_failure
  assert_output --partial 'usage: add-app [--cask]'
  run "$ROOT/scripts/add-app" my-app
  assert_failure
  assert_output --partial 'usage: add-app [--cask]'
}

@test "formula: writes the formula and release workflow from the latest release" {
  run "$ROOT/scripts/add-app" my-app "Does things"
  assert_success
  assert_output "Wrote $TAP_DIR/Formula/my-app.rb and $APP_DIR/.github/workflows/release.yml"
  run cat "$TAP_DIR/Formula/my-app.rb"
  assert_line 'class MyApp < Formula'
  assert_line '  desc "Does things"'
  assert_line '  homepage "https://github.com/willsawyerrrr/my-app"'
  assert_line '  url "https://github.com/willsawyerrrr/my-app/archive/refs/tags/v1.2.3.tar.gz"'
  assert_line "  sha256 \"$sha\""
  assert_line '    system bin/"my-app", "--version"'
  run cat "$APP_DIR/.github/workflows/release.yml"
  assert_line '      formula: my-app'
  refute_output --regexp '@[A-Z]+@'
}

@test "formula: refuses an existing formula" {
  mkdir -p "$TAP_DIR/Formula"
  echo keep > "$TAP_DIR/Formula/my-app.rb"
  run "$ROOT/scripts/add-app" my-app "Does things"
  assert_failure
  assert_output "$TAP_DIR/Formula/my-app.rb already exists"
  assert_equal "$(cat "$TAP_DIR/Formula/my-app.rb")" keep
  assert_not_exist "$APP_DIR"
}

@test "formula: fails without a release" {
  unset GH_TAG
  run "$ROOT/scripts/add-app" my-app "Does things"
  assert_failure
  assert_not_exist "$TAP_DIR/Formula/my-app.rb"
}

@test "formula: fails when the download fails" {
  CURL_FAIL=1 run "$ROOT/scripts/add-app" my-app "Does things"
  assert_failure
  assert_not_exist "$TAP_DIR/Formula/my-app.rb"
}

@test "cask: writes the cask and workflow from the latest release" {
  run "$ROOT/scripts/add-app" --cask my-app "Does things"
  assert_success
  assert_output "Wrote $TAP_DIR/Casks/my-app.rb and $APP_DIR/.github/workflows/release.yml"
  run cat "$TAP_DIR/Casks/my-app.rb"
  assert_line 'cask "my-app" do'
  assert_line '  version "1.2.3"'
  assert_line "  sha256 \"$sha\""
  assert_line '  url "https://github.com/willsawyerrrr/my-app/releases/download/v#{version}/MyApp.zip"'
  assert_line '  desc "Does things"'
  assert_line '  app "MyApp.app"'
  run cat "$APP_DIR/.github/workflows/release.yml"
  assert_line '      cask: my-app'
  assert_line '      asset: MyApp.zip'
  refute_output --regexp '@[A-Z]+@'
  assert_not_exist "$TAP_DIR/Formula"
}

@test "cask: APP_BUNDLE overrides the bundle name" {
  APP_BUNDLE=Custom run "$ROOT/scripts/add-app" --cask my-app "Does things"
  assert_success
  run cat "$TAP_DIR/Casks/my-app.rb"
  assert_line --partial 'releases/download/v#{version}/Custom.zip'
  run cat "$APP_DIR/.github/workflows/release.yml"
  assert_line '      asset: Custom.zip'
}

@test "cask: starts at 0.0.0 with a zero checksum when there is no release" {
  unset GH_TAG
  run "$ROOT/scripts/add-app" --cask my-app "Does things"
  assert_success
  run cat "$TAP_DIR/Casks/my-app.rb"
  assert_line '  version "0.0.0"'
  assert_line "  sha256 \"$(printf '0%.0s' {1..64})\""
}

@test "cask: starts at 0.0.0 when the release lacks the zip" {
  CURL_FAIL=1 run "$ROOT/scripts/add-app" --cask my-app "Does things"
  assert_success
  run cat "$TAP_DIR/Casks/my-app.rb"
  assert_line '  version "0.0.0"'
}

@test "cask: adds one row to the tap README" {
  mkdir -p "$TAP_DIR"
  printf '| App | Description |\n' > "$TAP_DIR/README.md"
  run "$ROOT/scripts/add-app" --cask my-app "Does things"
  assert_success
  assert_equal "$(tail -n1 "$TAP_DIR/README.md")" '| `my-app` | Does things |'
  assert_equal "$(grep -c 'my-app' "$TAP_DIR/README.md")" 1
}

@test "cask: leaves a missing tap README alone" {
  run "$ROOT/scripts/add-app" --cask my-app "Does things"
  assert_success
  assert_not_exist "$TAP_DIR/README.md"
}

@test "cask: refuses an existing cask" {
  mkdir -p "$TAP_DIR/Casks"
  echo keep > "$TAP_DIR/Casks/my-app.rb"
  run "$ROOT/scripts/add-app" --cask my-app "Does things"
  assert_failure
  assert_output "$TAP_DIR/Casks/my-app.rb already exists"
  assert_equal "$(cat "$TAP_DIR/Casks/my-app.rb")" keep
  assert_not_exist "$APP_DIR"
}
