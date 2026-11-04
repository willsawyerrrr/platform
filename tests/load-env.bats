# shellcheck disable=SC2016  # test bodies are deliberately single-quoted
setup() {
  load test_helper
  setup_sandbox
  ENV_A="$SANDBOX/a.env"
  ENV_B="$SANDBOX/b.env"
}

@test "runs a command with the variables set" {
  printf 'A=1\n# comment\n\nB=two words\nexport C=3\n' > "$ENV_A"
  run "$ROOT/scripts/load-env" "$ENV_A" -- sh -c 'echo "$A|$B|$C"'
  assert_success
  assert_output '1|two words|3'
}

@test "a later file wins on a clash" {
  printf 'A=first\nB=only-a\n' > "$ENV_A"
  printf 'A=second\n' > "$ENV_B"
  run "$ROOT/scripts/load-env" "$ENV_A" "$ENV_B" -- sh -c 'echo "$A|$B"'
  assert_output 'second|only-a'
}

@test "strips quotes and keeps single quotes in values" {
  printf 'A="x y"\nB='"'"'p q'"'"'\nC=it'"'"'s\nD=\n' > "$ENV_A"
  run "$ROOT/scripts/load-env" "$ENV_A" -- sh -c 'echo "$A|$B|$C|[$D]"'
  assert_output "x y|p q|it's|[]"
}

@test "accepts unquoted multi-line PEM values" {
  printf 'A=1\nKEY=-----BEGIN PRIVATE KEY-----\nabc\ndef\n-----END PRIVATE KEY-----\nB=2\n' > "$ENV_A"
  run "$ROOT/scripts/load-env" "$ENV_A" -- sh -c 'echo "$A|$B"; printf "%s\n" "$KEY"'
  assert_success
  assert_line --index 0 '1|2'
  assert_line --index 1 -- '-----BEGIN PRIVATE KEY-----'
  assert_line --index 2 'abc'
  assert_line --index 4 -- '-----END PRIVATE KEY-----'
}

@test "accepts quoted multi-line values" {
  printf 'A="l1\nl2"\nB=2\n' > "$ENV_A"
  run "$ROOT/scripts/load-env" "$ENV_A" -- sh -c 'echo "$B"; printf "%s\n" "$A"'
  assert_line --index 0 '2'
  assert_line --index 1 'l1'
  assert_line --index 2 'l2'
}

@test "reads a file that can only be read once, like a mounted FIFO" {
  mkfifo "$ENV_A"
  { printf 'A=1\n' > "$ENV_A"; } &
  run "$ROOT/scripts/load-env" "$ENV_A" -- sh -c 'echo "$A"'
  assert_output 1
}

@test "--print writes export statements" {
  printf 'A=1\nB=it'"'"'s\n' > "$ENV_A"
  run "$ROOT/scripts/load-env" --print "$ENV_A"
  assert_success
  assert_line --index 0 "export A='1'"
  assert_line --index 1 "export B='it'\\''s'"
}

@test "fails on an unreadable file" {
  run "$ROOT/scripts/load-env" "$SANDBOX/missing.env" -- true
  assert_failure
  assert_output --partial 'cannot read'
}

@test "requires files and a command" {
  run "$ROOT/scripts/load-env"
  assert_failure
  assert_output --partial 'usage: load-env'
  printf 'A=1\n' > "$ENV_A"
  run "$ROOT/scripts/load-env" "$ENV_A"
  assert_failure
  assert_output --partial 'usage: load-env'
}
