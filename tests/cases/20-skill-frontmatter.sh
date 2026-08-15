#!/usr/bin/env bash
# The frontmatter block every skill opens with.
#
# This is where git-tools has actually been broken before. In 0.2.1 the
# `release` skill shipped with an unquoted description containing
# `` `chore: release X.Y.Z` ``; YAML reads an embedded ': ' as a nested mapping,
# the parse failed, and every field — name, description, allowed-tools, model —
# was silently dropped. The skill loaded with no metadata at all and could never
# be triggered. Nothing about the file looked wrong.
. "$(dirname "$0")/../lib/harness.sh"

test_the_expected_skills_are_the_ones_on_disk() {
  desc "skills — the plugin ships exactly the six skills this suite knows about"
  # A skill added without a line here is a skill nobody decided to test.
  found="$(for s in $(skill_files); do basename "$(dirname "$s")"; done | sort | tr '\n' ' ')"
  assert_eq "$found" "branch changelog commit init release versioning " \
    "the skill directories under skills/"
}

test_every_skill_opens_with_frontmatter() {
  desc "every SKILL.md — opens with a --- block of key: value pairs"
  for s in $(skill_files); do
    [ "$(head -1 "$s")" = "---" ] || _fail "$(rel "$s") does not open with ---"
    [ -n "$(frontmatter "$s")" ] || _fail "$(rel "$s") has an empty frontmatter block"
    bad="$(frontmatter "$s" | grep -v '^[A-Za-z_][A-Za-z0-9_-]*:' | grep -v '^[[:space:]]*$')"
    [ -z "$bad" ] || _fail \
      "$(rel "$s") has a frontmatter line that is not a key: value pair" "$bad"
  done
}

test_no_unquoted_value_contains_a_colon_space() {
  desc "every SKILL.md — an unquoted frontmatter value never contains ': '"
  # The 0.2.1 bug exactly. `description: Cut a release: one pass` parses as a
  # nested mapping and takes the whole block down with it.
  for s in $(skill_files); do
    offenders="$(frontmatter "$s" | awk '{
      idx = index($0, ":")
      if (idx == 0) next
      v = substr($0, idx + 1)
      sub(/^[ \t]+/, "", v)
      first = substr(v, 1, 1)
      if (first == "\"" || first == "'"'"'" || v == "") next
      if (index(v, ": ") > 0) print substr($0, 1, idx - 1)
    }')"
    [ -z "$offenders" ] || _fail \
      "$(rel "$s"): an unquoted value contains ': ', which YAML reads as a nested mapping" \
      "key(s): $(printf '%s' "$offenders" | tr '\n' ' ')" \
      "quote the value and the whole block survives"
  done
}

test_every_skill_name_matches_its_directory() {
  desc "every SKILL.md — the frontmatter name is the directory name"
  # A plugin skill is invoked as /git-tools:<directory>, while `name` is what the
  # file calls itself. When the two disagree the skill is listed under one name
  # and answers to another, and every cross-reference in the file points at a
  # command that does not exist.
  for s in $(skill_files); do
    dir="$(basename "$(dirname "$s")")"
    assert_eq "$(fm_get "$s" name)" "$dir" \
      "the skill in $dir/ must call itself by its directory name"
  done
}

test_every_skill_declares_a_description() {
  desc "every SKILL.md — carries a description, which is what triggers it"
  for s in $(skill_files); do
    d="$(fm_get "$s" description)"
    assert_ne "$d" "" "$(rel "$s") must declare a description"
    # A description is matched against what the user said. One short sentence
    # names the skill and nothing else, and the skill then never fires.
    [ "${#d}" -ge 80 ] || _fail \
      "$(rel "$s") has a description too short to match anything" \
      "description: $d"
  done
}

test_every_skill_declares_allowed_tools_and_a_model() {
  desc "every SKILL.md — declares allowed-tools and a model"
  for s in $(skill_files); do
    assert_ne "$(fm_get "$s" allowed-tools)" "" "$(rel "$s") must declare allowed-tools"
    assert_matches "$(fm_get "$s" model)" '^(fable|opus|sonnet|haiku|inherit)$' \
      "$(rel "$s") must name a model tier"
  done
}

test_allowed_tools_covers_every_git_subcommand_in_the_context_block() {
  desc "every SKILL.md — every git subcommand it reads at load time is in allowed-tools"
  # A context command runs whatever the permissions say, but the skill goes on to
  # re-run the same subcommands as it works. One present in the context block and
  # absent from allowed-tools is a prompt for permission mid-task, on a command
  # the skill has already run once.
  n=0
  for s in $(skill_files); do
    allowed="$(fm_get "$s" allowed-tools)"
    subs="$(context_commands "$s" | grep -o 'git [a-z][a-z-]*' | awk '{print $2}' | sort -u)"
    while IFS= read -r sub; do
      [ -n "$sub" ] || continue
      n=$((n + 1))
      assert_contains "$allowed" "Bash(git $sub:" \
        "$(rel "$s") reads \`git $sub\` at load time but does not allow it"
    done <<EOF
$subs
EOF
  done
  assert_ne "$n" "0" "git subcommands must be found at all"
  note "$n git subcommand uses checked against allowed-tools"
}

run_cases
