#!/usr/bin/env bash
# The marketplace manifest this repository publishes itself through.
#
# git-tools is both a plugin and the marketplace that carries it: the entry in
# `plugins[]` points at `./`, the repository root, which is also the plugin
# root. That doubling is the whole reason for this file — the same facts are
# now written down twice, in `plugin.json` and in the entry beside it, and
# nothing but a test keeps the two copies agreeing.
#
# The version pair is the one that bites. `plugin.json` wins at install time
# and the entry's version is silently ignored, so a release that bumps one and
# forgets the other publishes a catalogue advertising a version nobody
# receives. `claude plugin validate` reports it — as a *warning*, exit 0 — so
# it is asserted here rather than left to the CLI's status.
. "$(dirname "$0")/../lib/harness.sh"

has_claude() { command -v claude >/dev/null 2>&1; }
has_jq() { command -v jq >/dev/null 2>&1; }

# mp_get JQ_FILTER — a value from the marketplace manifest. jq only: this file
# reads nested objects and an array, which sed cannot do honestly.
mp_get() { jq -r "$1 // empty" "$MARKETPLACE"; }

# The single plugin entry, by the name the manifest is expected to carry.
entry() { jq -r --arg n "git-tools" "(.plugins[] | select(.name == \$n) | $1) // empty" "$MARKETPLACE"; }

plugin_get() { jq -r "$1 // empty" "$MANIFEST"; }

# Every test below needs jq. Announce that once, in one place.
need_jq() {
  has_jq && return 0
  note "skipped: jq is not on PATH"
  return 1
}

test_the_marketplace_manifest_is_where_the_loader_looks() {
  desc "marketplace.json — lives at .claude-plugin/marketplace.json"
  # `/plugin marketplace add thedoobieapp/git-tools` fetches this path and
  # nothing else; anywhere else and the repository is a plugin nobody can add.
  assert_file "$MARKETPLACE" "the manifest a marketplace is discovered by"
}

test_the_marketplace_manifest_parses_as_json() {
  desc "marketplace.json — parses as JSON"
  need_jq || return 0
  jq -e . "$MARKETPLACE" >/dev/null 2>&1 \
    || _fail "the marketplace manifest must be valid JSON" "$(cat "$MARKETPLACE")"
}

test_the_marketplace_is_named_what_the_install_line_says() {
  desc "marketplace.json — named git-tools, which is the half of git-tools@git-tools users type"
  need_jq || return 0
  # A marketplace name is public-facing and registered one-per-name: adding a
  # second marketplace under this name replaces the first on that user's
  # machine. Renaming it therefore breaks every install line in the README and
  # silently displaces whatever else the user had under the new name — a
  # decision, not a typo, so the literal is asserted.
  assert_eq "$(mp_get .name)" "git-tools" "the marketplace name"
  assert_matches "$(mp_get .name)" '^[a-z0-9]+(-[a-z0-9]+)*$' \
    "and it is kebab-case, which is what /plugin install can carry"
}

test_the_marketplace_name_is_not_one_anthropic_reserved() {
  desc "marketplace.json — the name is not reserved for Anthropic's own marketplaces"
  need_jq || return 0
  # Reserved names are re-checked on every load, not only when added: a
  # marketplace that takes one stops loading for everyone who has it, reported
  # as registered from an untrusted source. Names that merely impersonate an
  # official source are blocked too, so the pattern check is the honest half.
  name="$(mp_get .name)"
  for reserved in claude-code-marketplace claude-code-plugins claude-plugins-official \
                  claude-plugins-community claude-community anthropic-marketplace \
                  anthropic-plugins agent-skills anthropic-agent-skills \
                  knowledge-work-plugins life-sciences claude-for-legal \
                  claude-for-financial-services financial-services-plugins \
                  first-party-plugins healthcare; do
    assert_ne "$name" "$reserved" "the marketplace name is reserved for Anthropic"
  done
  printf '%s' "$name" | grep -Eqi '(official|anthropic)' \
    && _fail "the name reads as an official Anthropic source, which is blocked" "name: $name"
  return 0
}

test_the_marketplace_says_who_maintains_it() {
  desc "marketplace.json — an owner with a name and a contact address"
  need_jq || return 0
  assert_ne "$(mp_get .owner.name)" "" "an owner name, which the schema requires"
  assert_matches "$(mp_get .owner.email)" '^[^@ ]+@[^@ ]+\.[a-z]+$' \
    "an owner email that is an address"
}

test_the_marketplace_lists_this_plugin_at_the_repository_root() {
  desc "marketplace.json — one entry, git-tools, sourced from the repository root"
  need_jq || return 0
  assert_eq "$(mp_get '.plugins | length')" "1" \
    "the marketplace carries exactly this plugin"
  assert_ne "$(entry .name)" "" "an entry named git-tools, matching the plugin manifest"
  src="$(entry .source)"
  # The plugin *is* the repository: `./` is the marketplace root, which is the
  # directory holding .claude-plugin/ — not the .claude-plugin/ directory.
  assert_matches "$src" '^\./?$' "the source must be the marketplace root"
  assert_not_contains "$src" ".." "a source path that climbs out of the marketplace"
  assert_file "$PLUGIN_ROOT/$src/.claude-plugin/plugin.json" \
    "the source must resolve to a directory holding a plugin manifest"
}

test_the_entry_and_the_plugin_manifest_agree() {
  desc "marketplace.json — name, version and license match .claude-plugin/plugin.json"
  need_jq || return 0
  # The version is the pair `claude plugin validate` warns about and exits 0 on.
  assert_eq "$(entry .version)" "$(plugin_get .version)" \
    "the entry's version and the plugin manifest's — plugin.json wins at install"
  assert_eq "$(entry .name)" "$(plugin_get .name)" \
    "the entry's name and the plugin manifest's"
  assert_eq "$(entry .license)" "$(plugin_get .license)" \
    "the entry's license and the plugin manifest's"
}

test_the_entry_carries_what_a_listing_needs() {
  desc "marketplace.json — the entry has a description, an author, a homepage and keywords"
  need_jq || return 0
  # This is the row a user reads in /plugin before installing anything, and the
  # text a search matches. It is filled in from the entry, not from the plugin.
  for field in .description .displayName .homepage .author.name; do
    assert_ne "$(entry "$field")" "" "the entry must declare $field"
  done
  assert_ne "$(entry '.keywords | length')" "0" \
    "keywords, which are what a search in /plugin matches"
}

test_the_readme_documents_the_marketplace_it_actually_declares() {
  desc "README.md — its install lines name this marketplace and this plugin"
  need_jq || return 0
  # Nothing else catches this: the manifest can be renamed and every test above
  # still passes while the README tells people to type a name that no longer
  # exists.
  readme="$(cat "$PLUGIN_ROOT/README.md")"
  assert_contains "$readme" "/plugin install git-tools@$(mp_get .name)" \
    "the README must document the install line this manifest makes possible"
  assert_contains "$readme" "/plugin marketplace add" \
    "and the marketplace add line that has to come first"
}

test_the_marketplace_validates() {
  desc "claude plugin validate — the marketplace validates, warnings included"
  if ! has_claude; then
    note "skipped: the claude CLI is not on PATH"
    return 0
  fi
  # Pointed at a directory holding both manifests, the CLI validates the
  # marketplace and descends into each local-source entry's plugin.json. A
  # warning leaves the status at 0, so the output is read as well.
  try claude plugin validate "$PLUGIN_ROOT"
  assert_ok "the marketplace must validate"
  assert_not_contains "$OUT" "warning" "the marketplace must validate without warnings"
}

run_cases
