setup() {
  load test_helper
  setup_sandbox
  openssl ecparam -name prime256v1 -genkey -noout | openssl pkcs8 -topk8 -nocrypt -out "$SANDBOX/key.p8"
  export ASC_KEY_ID=KEY ASC_ISSUER_ID=ISSUER
  export FETCH_ROUTES="$SANDBOX/routes.json" FETCH_LOG="$SANDBOX/fetch.log"
  echo "[]" > "$FETCH_ROUTES"
  export NODE_OPTIONS="--import $BATS_TEST_DIRNAME/fixtures/fetch-stub.mjs"
}

attach() { run node "$ROOT/scripts/attach-build" "$SANDBOX/key.p8" dev.example.app 1.2 42; }

app='{ "expect": "GET /v1/apps?", "body": { "data": [{ "id": "A1" }] } }'
valid='{ "expect": "GET /v1/builds?", "body": { "data": [{ "id": "B1", "attributes": { "processingState": "VALID" } }] } }'
attach_patch='{ "expect": "PATCH /v1/appStoreVersions/V1/relationships/build", "status": 204 }'

@test "requires all arguments and credentials" {
  run node "$ROOT/scripts/attach-build" "$SANDBOX/key.p8" dev.example.app 1.2
  assert_failure
  assert_output --partial 'usage: attach-build'
  ASC_KEY_ID='' run node "$ROOT/scripts/attach-build" "$SANDBOX/key.p8" dev.example.app 1.2 42
  assert_failure
  assert_output --partial 'usage: attach-build'
}

@test "attaches the build to the existing App Store version" {
  echo "[$app, $valid,
    { \"expect\": \"GET /v1/apps/A1/appStoreVersions?\", \"body\": { \"data\": [
      { \"id\": \"V0\", \"attributes\": { \"versionString\": \"1.1\", \"appStoreState\": \"READY_FOR_SALE\" } },
      { \"id\": \"V1\", \"attributes\": { \"versionString\": \"1.2\", \"appStoreState\": \"PREPARE_FOR_SUBMISSION\" } }] } },
    $attach_patch]" > "$FETCH_ROUTES"
  attach
  assert_success
  assert_output 'Attached build 42 to App Store version 1.2'
  run cat "$FETCH_LOG"
  assert_line --partial 'GET /v1/apps?filter%5BbundleId%5D=dev.example.app Bearer eyJ'
  assert_line --partial 'filter%5Bversion%5D=42'
  assert_line --partial 'PATCH /v1/appStoreVersions/V1/relationships/build'
  assert_line --partial '"id":"B1"'
}

@test "creates the App Store version when none matches" {
  echo "[$app, $valid,
    { \"expect\": \"GET /v1/apps/A1/appStoreVersions?\", \"body\": { \"data\": [] } },
    { \"expect\": \"POST /v1/appStoreVersions\", \"body\": { \"data\": { \"id\": \"V1\" } } },
    $attach_patch]" > "$FETCH_ROUTES"
  attach
  assert_success
  assert_line 'Created App Store version 1.2'
  assert_line 'Attached build 42 to App Store version 1.2'
  run cat "$FETCH_LOG"
  assert_line --partial '"versionString":"1.2"'
}

@test "leaves an App Store version that is no longer editable" {
  echo "[$app, $valid,
    { \"expect\": \"GET /v1/apps/A1/appStoreVersions?\", \"body\": { \"data\": [{ \"id\": \"V1\", \"attributes\": { \"versionString\": \"1.2\", \"appStoreState\": \"WAITING_FOR_REVIEW\" } }] } }]" > "$FETCH_ROUTES"
  attach
  assert_success
  assert_output 'App Store version 1.2 is WAITING_FOR_REVIEW and cannot take a new build; leaving it as it is'
}

@test "waits for the build to finish processing" {
  processing='{ "expect": "GET /v1/builds?", "body": { "data": [{ "id": "B1", "attributes": { "processingState": "PROCESSING" } }] } }'
  echo "[$app, $processing, $processing, $valid,
    { \"expect\": \"GET /v1/apps/A1/appStoreVersions?\", \"body\": { \"data\": [{ \"id\": \"V1\", \"attributes\": { \"versionString\": \"1.2\", \"appStoreState\": \"PREPARE_FOR_SUBMISSION\" } }] } },
    $attach_patch]" > "$FETCH_ROUTES"
  attach
  assert_success
  assert_equal "$(grep -c 'Waiting for build 42' <<< "$output")" 2
}

@test "fails when no app has the bundle ID" {
  echo '[{ "expect": "GET /v1/apps?", "body": { "data": [] } }]' > "$FETCH_ROUTES"
  attach
  assert_failure
  assert_output --partial 'Expected one app with bundle ID dev.example.app, found 0'
}

@test "fails when the build is invalid" {
  echo "[$app, { \"expect\": \"GET /v1/builds?\", \"body\": { \"data\": [{ \"id\": \"B1\", \"attributes\": { \"processingState\": \"INVALID\" } }] } }]" > "$FETCH_ROUTES"
  attach
  assert_failure
  assert_output --partial 'Build 42 is INVALID'
}

@test "fails when the build never appears" {
  echo "[$app$(printf ', { "expect": "GET /v1/builds?", "body": { "data": [] } }%.0s' {1..60})]" > "$FETCH_ROUTES"
  attach
  assert_failure
  assert_output --partial 'Build 42 did not finish processing'
}

@test "reports API errors" {
  echo '[{ "expect": "GET /v1/apps?", "status": 401, "body": { "errors": [] } }]' > "$FETCH_ROUTES"
  attach
  assert_failure
  assert_output --partial 'GET /v1/apps?filter%5BbundleId%5D=dev.example.app: 401'
}
