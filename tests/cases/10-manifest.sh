#!/usr/bin/env bash
# The plugin manifest, and the changelog that has to agree with it.
#
# `claude plugin validate` is the check the marketplace runs in CI; it is
# skipped rather than failed when the CLI is not on PATH, so the rest of the
# suite still runs in a bare environment.
#
# The version pairing is here because this plugin is the one that teaches
# releases. A `chore: release X.Y.Z` that bumped the manifest and left the
# changelog behind would be the `release` skill's own advice, unfollowed.
. "$(dirname "$0")/../lib/harness.sh"

has_claude() { command -v claude >/dev/null 2>&1; }

# json_get FILE KEY — a top-level string value, with a sed fallback so the suite
# still means something where jq is not installed.
json_get() {
  if command -v jq >/dev/null 2>&1; then
    jq -r --arg k "$2" '.[$k] // empty' "$1"
  else
    sed -n "s/^[[:space:]]*\"$2\"[[:space:]]*:[[:space:]]*\"\([^\"]*\)\".*/\1/p" "$1" | head -1
  fi
}

changelog_latest_version() {
  sed -n 's/^## \[\([0-9][^]]*\)\].*/\1/p' "$PLUGIN_ROOT/CHANGELOG.md" | head -1
}

test_the_manifest_is_where_the_loader_looks() {
  desc "plugin.json — lives at .claude-plugin/plugin.json"
  assert_file "$MANIFEST" "the manifest a plugin is discovered by"
}

test_the_manifest_parses_as_json() {
  desc "plugin.json — parses as JSON"
  if command -v jq >/dev/null 2>&1; then
    jq -e . "$MANIFEST" >/dev/null 2>&1 \
      || _fail "the manifest must be valid JSON" "$(cat "$MANIFEST")"
  else
    note "skipped the parse: jq is not on PATH"
  fi
}

test_the_manifest_declares_the_name_the_skills_are_invoked_by() {
  desc "plugin.json — declares the name every skill is invoked by, git-tools"
  # Skills are invoked as /<plugin name>:<skill>, and the name comes from here,
  # not from the directory — an installed copy may sit anywhere under any name.
  # The literal is the point: renaming the plugin renames every slash command
  # its own documents tell the user to type, so it is a decision, not a typo.
  assert_eq "$(json_get "$MANIFEST" name)" "git-tools" \
    "the name in the manifest"
  assert_matches "$(json_get "$MANIFEST" name)" '^[a-z0-9]+(-[a-z0-9]+)*$' \
    "and it is lowercase kebab-case, which is what a slash command can carry"
}

test_the_manifest_carries_what_a_listing_needs() {
  desc "plugin.json — description, author, license and keywords are all present"
  for key in displayName description license; do
    assert_ne "$(json_get "$MANIFEST" "$key")" "" "the manifest must declare $key"
  done
  if command -v jq >/dev/null 2>&1; then
    assert_ne "$(jq -r '.author.name // empty' "$MANIFEST")" "" "an author name"
    assert_matches "$(jq -r '.author.email // empty' "$MANIFEST")" '^[^@ ]+@[^@ ]+\.[a-z]+$' \
      "an author email that is an address"
    assert_ne "$(jq -r '.keywords | length' "$MANIFEST")" "0" \
      "keywords, which are what a search in the marketplace matches"
  else
    note "skipped the author and keyword checks: jq is not on PATH"
  fi
}

test_the_version_is_semver() {
  desc "plugin.json — the version is a Semantic Versioning number"
  assert_matches "$(json_get "$MANIFEST" version)" '^[0-9]+\.[0-9]+\.[0-9]+([-+].*)?$' \
    "the version this plugin's own versioning skill would insist on"
}

test_the_changelog_matches_the_manifest() {
  desc "CHANGELOG.md — its latest release is the version the manifest declares"
  assert_file "$PLUGIN_ROOT/CHANGELOG.md" "the plugin's changelog"
  assert_eq "$(changelog_latest_version)" "$(json_get "$MANIFEST" version)" \
    "the newest released heading and the manifest version"
}

test_the_changelog_keeps_its_format() {
  desc "CHANGELOG.md — opens as Keep a Changelog and keeps an Unreleased section"
  c="$PLUGIN_ROOT/CHANGELOG.md"
  assert_eq "$(head -1 "$c")" "# Changelog" "the title Keep a Changelog 1.1.0 specifies"
  grep -q '^## \[Unreleased\]' "$c" \
    || _fail "the changelog must keep an Unreleased section for work in flight"
  # Released headings carry a date; Unreleased is the only one that may not.
  bad="$(grep '^## \[' "$c" | grep -v '^## \[Unreleased\]' | grep -v ' - [0-9][0-9][0-9][0-9]-[0-9][0-9]-[0-9][0-9]$')"
  assert_empty "$bad" "every released heading carries an ISO date"
}

test_the_plugin_validates() {
  desc "claude plugin validate — the plugin validates on its own"
  if ! has_claude; then
    note "skipped: the claude CLI is not on PATH"
    return 0
  fi
  try claude plugin validate "$PLUGIN_ROOT"
  assert_ok "the plugin must validate without the marketplace around it"
}

run_cases
