# shellcheck disable=SC2016  # stub bodies are deliberately single-quoted
setup() {
  load test_helper
  setup_sandbox
  repo="$SANDBOX/repo"
  mkdir -p "$repo/ios/App.xcodeproj"
  git -C "$repo" init -q
  git -C "$repo" -c user.name=t -c user.email=t@t commit -q --allow-empty -m init
  export DEVICE=phone-1
  stub xcodegen
  stub xcrun
  stub xcodebuild '
    if [[ " $* " == *" -showBuildSettings "* ]]; then
      echo "[{\"buildSettings\":{\"WRAPPER_EXTENSION\":\"app\",\"TARGET_BUILD_DIR\":\"/build\",\"FULL_PRODUCT_NAME\":\"App.app\"}}]"
    fi'
}

@test "rejects unknown arguments" {
  run "$ROOT/scripts/deploy-to-device" --bogus
  assert_failure 2
  assert_output 'unknown argument: --bogus'
}

@test "requires --name and --repo" {
  run "$ROOT/scripts/deploy-to-device" --name App
  assert_failure 2
  assert_output --partial 'usage: deploy-to-device'
}

@test "builds, installs on the device and records the install" {
  run "$ROOT/scripts/deploy-to-device" --name App --repo "$repo"
  assert_success
  assert_output --regexp 'Installed [0-9a-f]{40}$'
  run cat "$CALLS"
  assert_line --regexp "^xcodebuild -project App.xcodeproj -scheme App .* -quiet build\$"
  assert_line 'xcrun devicectl device install app --device phone-1 /build/App.app'
  assert_exist "$XDG_STATE_HOME/platform/App/last-deploy"
}

@test "skips when nothing changed since the last install" {
  "$ROOT/scripts/deploy-to-device" --name App --repo "$repo"
  : > "$CALLS"
  run "$ROOT/scripts/deploy-to-device" --name App --repo "$repo"
  assert_success
  assert_output --regexp '^Up to date '
  assert_equal "$(cat "$CALLS")" ''
}

@test "reinstalls on --force or when the checkout is dirty" {
  "$ROOT/scripts/deploy-to-device" --name App --repo "$repo"
  run "$ROOT/scripts/deploy-to-device" --name App --repo "$repo" --force
  assert_output --regexp '^Installed '
  git -C "$repo" -c user.name=t -c user.email=t@t commit -q --allow-empty -m next
  run "$ROOT/scripts/deploy-to-device" --name App --repo "$repo"
  assert_output --regexp '^Installed '
}

@test "runs xcodegen when the project has a project.yml" {
  [[ ! -x /opt/homebrew/bin/xcodegen ]] || skip "the script prefers a real xcodegen over the stub"
  touch "$repo/ios/project.yml"
  run "$ROOT/scripts/deploy-to-device" --name App --repo "$repo"
  assert_success
  run cat "$CALLS"
  assert_line 'xcodegen generate --quiet'
}

@test "fails without exactly one Xcode project" {
  mkdir "$repo/ios/Other.xcodeproj"
  run "$ROOT/scripts/deploy-to-device" --name App --repo "$repo"
  assert_failure
  assert_output --partial 'Expected exactly one .xcodeproj'
}

@test "fails without a paired iPhone" {
  unset DEVICE
  stub xcrun 'echo "{\"result\":{\"devices\":[]}}"'
  run "$ROOT/scripts/deploy-to-device" --name App --repo "$repo"
  assert_failure
  assert_output --partial 'No paired iPhone found'
}

@test "does not record the install when it fails" {
  stub xcrun 'exit 1'
  run "$ROOT/scripts/deploy-to-device" --name App --repo "$repo"
  assert_failure
  assert_not_exist "$XDG_STATE_HOME/platform/App/last-deploy"
}
