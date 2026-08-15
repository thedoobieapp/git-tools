#!/usr/bin/env bash
# Run the git-tools plugin's own test suite.
#
#   plugins/git-tools/tests/run-tests.sh            # everything
#   plugins/git-tools/tests/run-tests.sh context    # only case files whose name matches
#   VERBOSE=1 …/run-tests.sh                        # also print each test's notes
#
# The suite belongs to the plugin and depends on nothing outside it: it can be
# run from a checkout of the marketplace, from an installed copy of the plugin,
# or from a directory that holds nothing but git-tools. Every test runs in its
# own temp directory, and the run fails loudly if anything wrote into the plugin.
#
# Two environment variables form the whole contract with an outer runner, so the
# marketplace suite can fold this one in without either knowing the other's
# internals:
#
#   TEST_TALLY   a file to write "<passed> <failed>" into. When set, the trailing
#                summary is left to the caller, which is aggregating.
#   VERBOSE      1 to print the notes that passing tests record.

set -uo pipefail

TESTS_DIR="$(cd "$(dirname "$0")" && pwd)"
PLUGIN_ROOT="$(cd "$TESTS_DIR/.." && pwd)"

filter="${1:-}"

# The plugin ships as read-only material — skills, references, a manifest. A
# test that wrote into it would corrupt an installed copy, so the tree is
# fingerprinted going in and coming out.
#
# Two things are left out, both because they change under the suite's feet
# without the suite touching them: `.DS_Store`, which Finder rewrites whenever
# it feels like it, and `.git/`, whose index an editor's git integration
# refreshes on a timer. Either one would fail an otherwise clean run.
plugin_fingerprint() {
  find "$PLUGIN_ROOT" -type f \
      -not -path "$TESTS_DIR/*" -not -path "$PLUGIN_ROOT/.git/*" -not -name .DS_Store \
      -print0 2>/dev/null \
    | xargs -0 shasum 2>/dev/null \
    | sort
}

before="$(plugin_fingerprint)"

total_pass=0
total_fail=0
failed_files=""

tally="$(mktemp "${TMPDIR:-/tmp}/git-tools-tally-XXXXXX")"
trap 'rm -f "$tally"' EXIT

printf '\n'
for case_file in "$TESTS_DIR"/cases/*.sh; do
  [ -f "$case_file" ] || continue
  name="$(basename "$case_file" .sh)"
  case "$name" in
    *"$filter"*) ;;
    *) continue ;;
  esac

  printf '%s\n' "$name"
  GIT_TOOLS_TEST_TALLY="$tally" bash "$case_file"
  rc=$?

  p=0; f=0
  if [ -s "$tally" ]; then
    read -r p f < "$tally"
  fi
  : > "$tally"

  total_pass=$((total_pass + p))
  total_fail=$((total_fail + f))
  # A case file that dies before run_cases reports nothing; count it as a
  # failure so a broken test file is never mistaken for a passing one.
  if [ "$rc" -ne 0 ] && [ "$f" -eq 0 ]; then
    printf '  FAIL %s did not complete (exit %s)\n' "$name" "$rc"
    total_fail=$((total_fail + 1))
  fi
  [ "$rc" -eq 0 ] || failed_files="${failed_files:+$failed_files }$name"
  printf '\n'
done

if [ "$(plugin_fingerprint)" != "$before" ]; then
  printf 'The suite wrote into the plugin. That is a bug in the tests.\n' >&2
  total_fail=$((total_fail + 1))
  failed_files="${failed_files:+$failed_files }plugin-was-modified"
fi

printf '%s %s\n' "$total_pass" "$total_fail" > "${TEST_TALLY:-/dev/null}"

# Nested inside another runner, the totals belong to that runner's summary.
if [ -z "${TEST_TALLY:-}" ]; then
  printf -- '---\n'
  printf '%s passed, %s failed\n' "$total_pass" "$total_fail"
  [ "$total_fail" -eq 0 ] || printf 'failing: %s\n' "$failed_files"
fi

[ "$total_fail" -eq 0 ] || exit 1
exit 0
