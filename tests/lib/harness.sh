#!/usr/bin/env bash
# Test harness for the git-tools plugin.
#
# Sourced by every file in tests/cases/. Provides a `desc`/assert vocabulary and
# runs each test function in its own throwaway directory, so no test can ever
# see another test's state — or the plugin's.
#
# This file is deliberately a copy rather than a link to anything outside the
# plugin. git-tools ships as a self-contained directory: whoever installs it
# gets the skills, the references and the tests that prove them, and the suite
# has to run from that directory alone with nothing else on disk.
#
# Written for bash 3.2 (the macOS system bash) and BSD userland: no associative
# arrays, no `mapfile`, no GNU-only flags.
#
# A test is a shell function named `test_*`. It runs in a subshell whose working
# directory is a fresh temp dir. It fails by calling any assert that does not
# hold; the assert prints why and exits the subshell. `desc` names the contract
# under test, and is what a failure reports — never a line number.

set -uo pipefail

TESTS_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
PLUGIN_ROOT="$(cd "$TESTS_DIR/.." && pwd)"
SKILLS_DIR="$PLUGIN_ROOT/skills"
REFERENCES_DIR="$PLUGIN_ROOT/references"
MANIFEST="$PLUGIN_ROOT/.claude-plugin/plugin.json"

# Every SKILL.md the plugin ships, in a stable order.
skill_files() {
  find "${1:-$SKILLS_DIR}" -type f -name SKILL.md | sort
}

# Every shell script the plugin ships. git-tools carries none today — its skills
# are prose, not scripts — so the portability checks that read this list assert
# on what they find rather than on a count, and start covering a script the day
# one lands.
shipped_scripts() {
  find "$PLUGIN_ROOT" -type f -name '*.sh' -not -path "$TESTS_DIR/*" | sort
}

# ---------------------------------------------------------------- reporting

# `desc` marks the contract the current test is about. It is printed on stdout
# with a sentinel so the runner can pull it back out of a failed test's captured
# output — a subshell cannot hand a variable back to its parent.
desc() { printf '@@DESC@@%s\n' "$1"; }

# `note` records something the test established that is worth reading in the log
# even when it passes. Suppressed unless VERBOSE=1.
note() { [ "${VERBOSE:-0}" = "1" ] && printf '@@NOTE@@%s\n' "$1"; return 0; }

_fail() {
  printf '@@FAIL@@%s\n' "$1"
  shift
  while [ $# -gt 0 ]; do printf '@@INFO@@%s\n' "$1"; shift; done
  exit 1
}

# A path printed in a failure is relative to the plugin, not to whoever's disk
# the plugin happens to be sitting on.
rel() { printf '%s' "${1#"$PLUGIN_ROOT/"}"; }

# ---------------------------------------------------------------- running

# try CMD... — run a command, capturing combined output in $OUT and its exit
# status in $STATUS. Never fails itself, so the test stays in control.
try() {
  OUT="$("$@" 2>&1)"
  STATUS=$?
  return 0
}

# Make the current directory a git repository, configured enough to commit.
git_here() {
  git init -q . >/dev/null 2>&1
  git config user.email "test@example.com"
  git config user.name  "Test"
}

# ---------------------------------------------------------------- assertions

assert_eq() {
  local actual="$1" expected="$2" what="$3"
  [ "$actual" = "$expected" ] || _fail "$what" "expected: [$expected]" "actual:   [$actual]"
}

assert_ne() {
  local actual="$1" unwanted="$2" what="$3"
  [ "$actual" != "$unwanted" ] || _fail "$what" "should not have been: [$unwanted]"
}

assert_status() {
  local expected="$1" what="$2"
  [ "$STATUS" = "$expected" ] \
    || _fail "$what" "expected exit $expected, got $STATUS" "output: $OUT"
}

assert_ok() { assert_status 0 "$1"; }

assert_contains() {
  local haystack="$1" needle="$2" what="$3"
  case "$haystack" in
    *"$needle"*) ;;
    *) _fail "$what" "expected to contain: [$needle]" "actual: [$haystack]" ;;
  esac
}

assert_not_contains() {
  local haystack="$1" needle="$2" what="$3"
  case "$haystack" in
    *"$needle"*) _fail "$what" "should not contain: [$needle]" "actual: [$haystack]" ;;
  esac
}

assert_matches() {
  local value="$1" regex="$2" what="$3"
  printf '%s' "$value" | grep -Eq "$regex" \
    || _fail "$what" "expected to match: $regex" "actual: [$value]"
}

assert_file() {
  local f="$1" what="$2"
  [ -f "$f" ] || _fail "$what" "expected a file at: $f"
}

assert_dir() {
  local d="$1" what="$2"
  [ -d "$d" ] || _fail "$what" "expected a directory at: $d"
}

assert_empty() {
  local value="$1" what="$2"
  [ -z "$value" ] || _fail "$what" "$value"
}

# ---------------------------------------------------------------- skill files

# Print every !`…` command in a SKILL.md, one per line.
context_commands() {
  grep -o '!`[^`]*`' "$1" | sed 's/^!`//; s/`$//'
}

# Print the frontmatter block of a SKILL.md — everything between the opening
# `---` and the closing one.
frontmatter() {
  awk 'NR==1 { if ($0 != "---") exit 0; next } $0 == "---" { exit 0 } { print }' "$1"
}

# fm_get FILE KEY — one frontmatter value, unquoted keys only, first match wins.
fm_get() {
  frontmatter "$1" | awk -v key="$2" '
    { idx = index($0, ":"); if (idx == 0) next
      k = substr($0, 1, idx - 1); v = substr($0, idx + 1)
      gsub(/^[ \t]+|[ \t]+$/, "", k); gsub(/^[ \t]+|[ \t]+$/, "", v)
      if (k == key) { print v; exit 0 } }'
}

# check_skills SKILLS_DIR STATE — run every context command of every SKILL.md
# under SKILLS_DIR in the current directory, and fail naming the skill and the
# command.
#
# Each command runs in a fresh `bash -c` under default shell options, which is
# what the skill harness does. That matters: `set -o pipefail` would change the
# answer for the commands ending in `| head`, whose whole safety net is that the
# pipeline reports head's status and not git's. See the pipefail test.
check_skills() {
  local dir="$1" state="$2" skill cmd rc out
  local checked=0
  for skill in $(skill_files "$dir"); do
    [ -f "$skill" ] || continue
    while IFS= read -r cmd; do
      [ -n "$cmd" ] || continue
      checked=$((checked + 1))
      out="$(bash -c "$cmd" 2>&1)"
      rc=$?
      [ "$rc" -eq 0 ] || _fail \
        "context command exits $rc in $state — the skill would abort at load time" \
        "skill:   $(rel "$skill")" \
        "command: $cmd" \
        "output:  $out"
    done <<EOF
$(context_commands "$skill")
EOF
  done
  [ "$checked" -gt 0 ] || _fail "no context commands were found — the extraction is broken"
  note "$checked context command(s) checked in $state"
}

# ---------------------------------------------------------------- the runner

# Called at the end of each case file. Discovers every `test_*` function defined
# in it and runs each in a fresh temp directory.
run_cases() {
  local fn dir rc out d
  local passed=0 failed=0

  for fn in $(declare -F | sed -n 's/^declare -f \(test_[A-Za-z0-9_]*\)$/\1/p' | sort); do
    dir="$(mktemp -d "${TMPDIR:-/tmp}/git-tools-test-XXXXXX")"
    out="$( cd "$dir" && "$fn" 2>&1 )"
    rc=$?
    # A test may leave read-only files behind; force them out.
    chmod -R u+w "$dir" 2>/dev/null || true
    rm -rf "$dir"

    d="$(printf '%s\n' "$out" | sed -n 's/^@@DESC@@//p' | head -1)"
    [ -n "$d" ] || d="$fn"

    if [ "$rc" -eq 0 ]; then
      passed=$((passed + 1))
      printf '  ok   %s\n' "$d"
      printf '%s\n' "$out" | sed -n 's/^@@NOTE@@/       · /p'
    else
      failed=$((failed + 1))
      printf '  FAIL %s\n' "$d"
      printf '%s\n' "$out" | sed -n 's/^@@FAIL@@/       ✘ /p'
      printf '%s\n' "$out" | sed -n 's/^@@INFO@@/         /p'
      # Anything the test printed that is not harness chatter is real output
      # from whatever it ran, and is usually the reason.
      printf '%s\n' "$out" | grep -v '^@@' | sed -n '1,12p' | sed 's/^/         | /'
    fi
  done

  printf '%s %s\n' "$passed" "$failed" > "${GIT_TOOLS_TEST_TALLY:-/dev/null}"
  [ "$failed" -eq 0 ]
}
