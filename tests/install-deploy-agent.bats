# shellcheck disable=SC2016  # stub bodies are deliberately single-quoted
setup() {
  load test_helper
  setup_sandbox
  mkdir -p "$HOME/Library/LaunchAgents"
  stub launchctl
  plist="$HOME/Library/LaunchAgents/dev.willsawyerrrr.my-app-deploy.plist"
}

@test "requires --name" {
  run "$ROOT/scripts/install-deploy-agent" --repo /x
  assert_failure 2
  assert_output --partial 'usage: install-deploy-agent'
}

@test "writes a plist that runs deploy-main-to-device with the arguments" {
  run "$ROOT/scripts/install-deploy-agent" --name my-app --repo /work/my-app/main --scheme App
  assert_success
  assert_output 'Installed dev.willsawyerrrr.my-app-deploy'
  run cat "$plist"
  assert_line '  <key>Label</key><string>dev.willsawyerrrr.my-app-deploy</string>'
  assert_line "    <string>$ROOT/scripts/deploy-main-to-device</string>"
  assert_line '    <string>--repo</string>'
  assert_line '    <string>/work/my-app/main</string>'
  assert_line '    <string>--scheme</string>'
  assert_line "  <key>StandardOutPath</key><string>$HOME/Library/Logs/my-app-deploy.log</string>"
}

@test "escapes XML special characters in arguments" {
  run "$ROOT/scripts/install-deploy-agent" --name my-app --repo '/a&b/<c>'
  assert_success
  run cat "$plist"
  assert_line '    <string>/a&amp;b/&lt;c&gt;</string>'
  if command -v plutil > /dev/null; then run plutil -lint "$plist"; assert_success; fi
}

@test "reloads the agent through launchctl" {
  run "$ROOT/scripts/install-deploy-agent" --name my-app --repo /x
  assert_success
  run cat "$CALLS"
  assert_line --regexp '^launchctl bootout gui/[0-9]+/dev.willsawyerrrr.my-app-deploy$'
  assert_line --regexp "^launchctl bootstrap gui/[0-9]+ $plist\$"
}

@test "fails when launchctl cannot bootstrap" {
  stub launchctl '[[ "$1" != bootstrap ]] || exit 5'
  run "$ROOT/scripts/install-deploy-agent" --name my-app --repo /x
  assert_failure 5
}
