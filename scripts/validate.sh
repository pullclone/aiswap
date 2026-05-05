#!/usr/bin/env bash
set -euo pipefail

ROOT=$(CDPATH='' cd -- "$(dirname -- "${BASH_SOURCE[0]}")/.." && pwd)
TMPDIR=$(command mktemp -d)

cleanup() {
	command rm -rf "$TMPDIR"
}
trap cleanup EXIT INT TERM

fail() {
	command printf "FAIL: %s\n" "$*" >&2
	exit 1
}

assert_file_absent() {
	[[ ! -e "$1" ]] || fail "unexpected file exists: $1"
}

assert_file_exists() {
	[[ -e "$1" ]] || fail "expected file exists: $1"
}

assert_contains_line() {
	local file="$1" line="$2"
	command grep -Fx "$line" "$file" >/dev/null || fail "missing line '$line' in $file"
}

for shell_file in "$ROOT/aiswap" "$ROOT/aiswap.sh" "$ROOT/scripts/validate.sh"; do
	command bash -n "$shell_file"
done

export AICHAT_CONF_DIR="$TMPDIR/aichat"
# shellcheck source=/dev/null
source "$ROOT/aiswap.sh"

_aichat_swap init >/dev/null
assert_file_exists "$AICHAT_CONF_DIR"
assert_file_exists "$AICHAT_CONF_DIR/backups"
assert_file_absent "$AICHAT_CONF_DIR/config.yaml"
for id in c g m o; do
	assert_file_absent "$AICHAT_CONF_DIR/$id.config.yaml"
done

_aichat_swap alias add z zed >/dev/null
assert_contains_line "$AICHAT_CONF_DIR/aliases" "z zed"

_aichat_swap alias remove zed >/dev/null
if [[ -f "$AICHAT_CONF_DIR/aliases" ]]; then
	! command grep -F " zed" "$AICHAT_CONF_DIR/aliases" >/dev/null || fail "alias remove left zed behind"
fi

command printf "active-before\n" >"$AICHAT_CONF_DIR/config.yaml"
command printf "stored-c\n" >"$AICHAT_CONF_DIR/c.config.yaml"
command printf "target-g\n" >"$AICHAT_CONF_DIR/g.config.yaml"
command printf "c\n" >"$AICHAT_CONF_DIR/current"

before_config=$(command cksum "$AICHAT_CONF_DIR/config.yaml")
before_current=$(command cksum "$AICHAT_CONF_DIR/current")
_aichat_swap -n g >/dev/null
after_config=$(command cksum "$AICHAT_CONF_DIR/config.yaml")
after_current=$(command cksum "$AICHAT_CONF_DIR/current")
[[ "$before_config" == "$after_config" ]] || fail "dry-run mutated config.yaml"
[[ "$before_current" == "$after_current" ]] || fail "dry-run mutated current"
assert_file_absent "$AICHAT_CONF_DIR/.swap.lock.d"

if _aichat_swap m >/dev/null 2>&1; then
	fail "switch to missing profile succeeded"
fi

command printf "active-crlf\n" >"$AICHAT_CONF_DIR/config.yaml"
command printf "old-c\n" >"$AICHAT_CONF_DIR/c.config.yaml"
command printf "target-g\n" >"$AICHAT_CONF_DIR/g.config.yaml"
command printf "c\r\n" >"$AICHAT_CONF_DIR/current"
_aichat_swap g >/dev/null
[[ "$(command cat "$AICHAT_CONF_DIR/c.config.yaml")" == "active-crlf" ]] || fail "CRLF current marker was not treated as c"
[[ "$(command tr -d '\r\n' <"$AICHAT_CONF_DIR/current")" == "g" ]] || fail "current marker was not updated to g"
[[ "$(command cat "$AICHAT_CONF_DIR/config.yaml")" == "target-g" ]] || fail "active config was not switched to g"

command printf "PASS: aiswap validation complete\n"
