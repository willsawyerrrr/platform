# shellcheck disable=SC2016  # stub bodies are deliberately single-quoted
bats_load_library bats-support
bats_load_library bats-assert

ROOT="$(cd "$BATS_TEST_DIRNAME/.." && pwd)"
export ROOT

# Isolate each test: temp `HOME`, and a `PATH` shim dir that logs every stubbed call to `$CALLS`.
setup_sandbox() {
  SANDBOX="$BATS_TEST_TMPDIR"
  export HOME="$SANDBOX/home" XDG_STATE_HOME="$SANDBOX/state"
  mkdir -p "$HOME" "$SANDBOX/bin"
  export PATH="$SANDBOX/bin:$PATH"
  export CALLS="$SANDBOX/calls.log"
  : > "$CALLS"
}

# stub <name> [body]: shim that logs `<name> <args>` to `$CALLS`, then runs `body`.
stub() {
  printf '#!/usr/bin/env bash\necho "%s $*" >> "$CALLS"\n%s\n' "$1" "${2:-}" > "$SANDBOX/bin/$1"
  chmod +x "$SANDBOX/bin/$1"
}

# sha256_of <text>: checksum of `<text>` plus a newline, as the `curl` stub emits it.
sha256_of() { printf '%s\n' "$1" | shasum -a 256 | cut -d' ' -f1; }

assert_not_exist() { [[ ! -e "$1" ]] || fail "$1 exists"; }
assert_exist() { [[ -e "$1" ]] || fail "$1 does not exist"; }
