#!/usr/bin/env bash
# Whether the plugin is whole on its own.
#
# git-tools is installed as a directory: Claude Code copies it somewhere and
# sets ${CLAUDE_PLUGIN_ROOT} to that path. Nothing around it comes along — not
# the marketplace, not the sibling plugins, not this repository. Every file the
# skills name therefore has to be inside the plugin, and every path they name
# has to resolve from the plugin root alone.
#
# The failure this guards against has happened: 0.2.0 fixed reference links
# pointing at an Obsidian vault path that exists on nobody's disk, and one link
# that had dropped its directory. Both read perfectly in the SKILL.md.
. "$(dirname "$0")/../lib/harness.sh"

# The physical path of a directory, with /var/… resolved to /private/var/… so a
# containment check can compare two paths honestly.
abs_dir() { (cd "$1" 2>/dev/null && pwd -P); }

# Every markdown link in FILE that points at a path rather than a URL or an
# anchor. No `case` here: bash 3.2 misreads a case pattern's `)` inside `$( … )`
# as the end of the substitution, so the filtering is grep's.
markdown_links() {
  grep -o '](\([^)]*\))' "$1" | sed 's/^](//; s/)$//' | grep -v '^http' | grep -v '^#'
}

# Every path a file names through ${CLAUDE_PLUGIN_ROOT}, as a plugin-relative
# path. A trailing `…` in prose stops the match, which leaves the directory —
# and a directory is a path that must exist too.
plugin_root_paths() {
  grep -o '\${CLAUDE_PLUGIN_ROOT}[A-Za-z0-9._/-]*' "$1" | sed 's|^\${CLAUDE_PLUGIN_ROOT}||'
}

# broken_paths ROOT — every path named by a document under ROOT that does not
# resolve, or resolves outside ROOT. Prints one `file -> path (why)` per line.
#
# CHANGELOG.md is exempt. It is a record of what was true at each release, and
# an entry describing a directory that has since been removed names that
# directory correctly — 0.5.0 moved the references into `skills/docs/` and the
# entry saying so has to keep saying so. Holding a history to today's tree would
# force every past entry to be rewritten by whoever moves a file next, which is
# the one thing a changelog must not allow.
broken_paths() {
  local root="$1" f d link target parent abs
  root="$(abs_dir "$root")"
  for f in $(find "$root" -type f -name '*.md' -not -path "$root/tests/*" -not -name CHANGELOG.md); do
    d="$(dirname "$f")"
    while IFS= read -r link; do
      [ -n "$link" ] || continue
      target="$d/$link"
      if [ ! -e "$target" ]; then
        printf '%s -> %s (missing)\n' "${f#"$root/"}" "$link"
        continue
      fi
      parent="$(abs_dir "$(dirname "$target")")"
      abs="$parent/$(basename "$target")"
      # A link that climbs out of the plugin resolves here and nowhere else.
      expr "$abs" : "$root/" >/dev/null \
        || printf '%s -> %s (outside the plugin)\n' "${f#"$root/"}" "$link"
    done <<EOF
$(markdown_links "$f")
EOF
    while IFS= read -r link; do
      [ -n "$link" ] || continue
      [ -e "$root$link" ] \
        || printf '%s -> ${CLAUDE_PLUGIN_ROOT}%s (missing)\n' "${f#"$root/"}" "$link"
    done <<EOF
$(plugin_root_paths "$f")
EOF
  done
}

test_every_path_the_documents_name_resolves_inside_the_plugin() {
  desc "every link and \${CLAUDE_PLUGIN_ROOT} path resolves, and stays inside the plugin"
  broken="$(broken_paths "$PLUGIN_ROOT")"
  assert_empty "$broken" "a document names a path that is not there"
  note "$(find "$PLUGIN_ROOT" -type f -name '*.md' -not -path "$PLUGIN_ROOT/tests/*" -not -name CHANGELOG.md | wc -l | tr -d ' ') documents checked"
}

test_the_plugin_is_whole_when_copied_somewhere_else() {
  desc "a copy of the plugin alone still resolves every path it names"
  # This is what installation does: the directory, and nothing around it.
  cp -R "$PLUGIN_ROOT" ./git-tools
  rm -rf ./git-tools/.git
  broken="$(broken_paths ./git-tools)"
  assert_empty "$broken" "a path only resolved because the marketplace was around it"
}

test_the_suite_runs_from_that_copy() {
  desc "the suite itself runs from an installed copy, with no marketplace around it"
  if [ "${GIT_TOOLS_TESTS_NESTED:-0}" = "1" ]; then
    note "skipped: already running inside the nested copy"
    return 0
  fi
  cp -R "$PLUGIN_ROOT" ./git-tools
  rm -rf ./git-tools/.git
  # Only the context cases, and only one level deep: enough to prove the runner,
  # the harness and a case file work with nothing but the plugin on disk.
  #
  # Both tally variables are scrubbed first. They are exported by whichever
  # runner started this test, and the copy's runner would otherwise report its
  # numbers into the outer run's tally file — a nested suite of seven tests
  # overwriting the count of the suite that called it.
  OUT="$(cd ./git-tools && env -u TEST_TALLY -u GIT_TOOLS_TEST_TALLY \
    GIT_TOOLS_TESTS_NESTED=1 bash tests/run-tests.sh skill-context 2>&1)"
  STATUS=$?
  assert_ok "the copy's own suite must pass"
  assert_contains "$OUT" "0 failed" "and report no failures"
}

test_no_document_reaches_for_another_plugin() {
  desc "no skill or reference names a sibling plugin or a marketplace path"
  # `plugins/…` is a path that exists in the repository this plugin is developed
  # in and nowhere else. A skill that names one is reading a file that will not
  # be there once installed.
  # $SKILLS_DIR covers the references too — they live under it.
  offenders="$(grep -rn 'plugins/' "$SKILLS_DIR" 2>/dev/null)"
  assert_empty "$offenders" "a document points at a marketplace path"
  offenders="$(grep -rn '\.\./\.\./\.\.' "$SKILLS_DIR" 2>/dev/null)"
  assert_empty "$offenders" "a relative path climbs above the plugin root"
}

test_every_reference_file_is_used() {
  desc "references — every file is named by a skill, and every skill's is there"
  # The other half of completeness: a reference nothing reads is dead weight
  # shipped to every user, and it is usually the leftover of a link that moved.
  #
  # Only the SKILL.md files count as readers. The references cross-link each
  # other, so grepping the whole skills directory would find every file named by
  # a sibling and the test would pass on its own footprints.
  #
  # A reference no longer has to be read by the skill it sits under. Each one
  # lives beside its owner, but `release` owns none and reads three across —
  # version-sources from versioning, commit-type-mapping and keep-a-changelog
  # from changelog. So the contract is that *some* SKILL.md names the file, not
  # that its neighbour does.
  readers="$(skill_files)"
  unused=""
  for f in $(reference_files); do
    grep -q "$(basename "$f")" $readers \
      || unused="${unused:+$unused }$(rel "$f")"
  done
  assert_empty "$unused" "a reference file no skill points at"
  n="$(reference_files | grep -c . | tr -d ' ')"
  assert_ne "$n" "0" "the plugin must ship at least one reference"
  note "$n reference files, all of them read by at least one skill"
}

test_every_shell_file_parses_as_bash() {
  desc "every shell file the plugin carries parses as bash"
  for s in $(find "$PLUGIN_ROOT" -type f -name '*.sh' | sort); do
    bash -n "$s" 2>/dev/null || _fail "$(rel "$s") is not syntactically valid bash"
  done
}

test_shipped_scripts_are_bash_3_2_and_bsd_safe() {
  desc "any script the plugin ships avoids bash 4 and GNU-only constructs"
  # bash 3.2.57 is what /bin/bash is on macOS: no mapfile/readarray, no
  # associative arrays, no ${var,,}. BSD sed needs an argument to -i; GNU sed
  # refuses one. git-tools ships no scripts today — its skills are prose — so
  # this passes vacuously and starts meaning something the day one lands.
  n=0
  for s in $(shipped_scripts); do
    n=$((n + 1))
    code="$(sed 's/^[[:space:]]*#.*//' "$s")"
    printf '%s' "$code" | grep -qE '(^|[^[:alnum:]_])(mapfile|readarray)[[:space:]]' \
      && _fail "$(rel "$s") uses mapfile/readarray, absent in bash 3.2"
    printf '%s' "$code" | grep -qE '(declare|local|typeset)[[:space:]]+-[a-zA-Z]*A' \
      && _fail "$(rel "$s") uses an associative array, absent in bash 3.2"
    printf '%s' "$code" | grep -qE '\$\{[A-Za-z_][A-Za-z0-9_]*(,,|\^\^)' \
      && _fail "$(rel "$s") uses \${var,,} case conversion, absent in bash 3.2"
    printf '%s' "$code" | grep -qE "sed[^|;]*-i[[:space:]]+-?[a-zA-Z']" \
      && _fail "$(rel "$s") uses GNU-style 'sed -i' with no backup suffix"
  done
  note "$n shipped script(s) checked"
  return 0
}

run_cases
