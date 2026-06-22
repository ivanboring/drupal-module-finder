#!/usr/bin/env bash
#
# Tests for the bash completion of drupal-module-finder.
#
# Sources the emitted completion script, drives the _drupal_module_finder
# function by setting COMP_WORDS / COMP_CWORD, and asserts on COMPREPLY.
# No network and no Drupal needed: completion only reads static lists and the
# local cache directory (pointed at a temp dir via DRUPAL_MODULE_FINDER_CACHE).
#
# Run:  bash command/test-completion.sh

set -uo pipefail

CMD="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)/drupal-module-finder"

# Isolated cache so data-name completion is deterministic.
CACHE="$(mktemp -d)"
export DRUPAL_MODULE_FINDER_CACHE="$CACHE"
trap 'rm -rf "$CACHE"' EXIT
: >"$CACHE/privatemsg.json"
: >"$CACHE/pathauto.json"
# A release cache entry (no .json) must NOT show up as a data name.
: >"$CACHE/privatemsg--releases"

# The completion function calls `$cmd completion ...`; COMP_WORDS[0] must be a
# runnable command, so use the script's absolute path.
BIN="$CMD"

# Load the completion function under test.
# shellcheck disable=SC1090
source <("$CMD" completion bash)

pass=0
fail=0

# complete_for <cword> <word>...   -> populates COMPREPLY via the function.
complete_for() {
  local cword="$1"; shift
  COMP_WORDS=("$BIN" "$@")
  COMP_CWORD="$cword"
  COMPREPLY=()
  _drupal_module_finder
}

# reply_has <value> : true if COMPREPLY contains an exact value.
reply_has() {
  local want="$1" r
  for r in ${COMPREPLY[@]+"${COMPREPLY[@]}"}; do
    [ "$r" = "$want" ] && return 0
  done
  return 1
}

assert_has() {
  local desc="$1" want="$2"
  if reply_has "$want"; then
    pass=$((pass + 1))
  else
    fail=$((fail + 1))
    printf 'FAIL: %s\n      expected reply to contain: %q\n      got: %s\n' \
      "$desc" "$want" "${COMPREPLY[*]:-<empty>}"
  fi
}

assert_lacks() {
  local desc="$1" unwanted="$2"
  if reply_has "$unwanted"; then
    fail=$((fail + 1))
    printf 'FAIL: %s\n      expected reply NOT to contain: %q\n      got: %s\n' \
      "$desc" "$unwanted" "${COMPREPLY[*]:-<empty>}"
  else
    pass=$((pass + 1))
  fi
}

# --- Subcommand completion ------------------------------------------------
complete_for 1 ""
assert_has "subcommands include module-info" "module-info"
assert_has "subcommands include semantic-search" "semantic-search"
assert_has "subcommands include completion" "completion"

complete_for 1 "mod"
assert_has "prefix 'mod' completes module-info" "module-info"
assert_lacks "prefix 'mod' excludes readme" "readme"

# --- Data-name positional completion --------------------------------------
complete_for 2 "module-info" ""
assert_has "module-info offers cached data name privatemsg" "privatemsg"
assert_has "module-info offers cached data name pathauto" "pathauto"
assert_lacks "module-info hides --releases cache entry" "privatemsg--releases"

complete_for 2 "readme" "path"
assert_has "readme completes prefix path -> pathauto" "pathauto"
assert_lacks "readme prefix path excludes privatemsg" "privatemsg"

# semantic-search takes free text, not a data name.
complete_for 2 "semantic-search" "priv"
assert_lacks "semantic-search does not complete data names" "privatemsg"

# --- Option flags ---------------------------------------------------------
complete_for 2 "module-info" "-"
assert_has "module-info offers --all" "--all"
assert_has "module-info offers --fields=" "--fields="
assert_lacks "module-info does not offer --chunk=" "--chunk="

complete_for 2 "semantic-search" "-"
assert_has "semantic-search offers --chunk=" "--chunk="

complete_for 2 "install-skill" "-"
assert_has "install-skill offers --agent=" "--agent="

# --- Value completion for = options ---------------------------------------
complete_for 2 "module-info" "--fields="
assert_has "--fields= offers stars" "--fields=stars"
assert_has "--fields= offers title" "--fields=title"

complete_for 2 "module-info" "--fields=stars,sec"
assert_has "--fields= is comma-aware" "--fields=stars,security_covered"

complete_for 2 "install-skill" "--agent="
assert_has "--agent= offers claude" "--agent=claude"

# --- Summary --------------------------------------------------------------
printf '\n%d passed, %d failed\n' "$pass" "$fail"
[ "$fail" -eq 0 ]
