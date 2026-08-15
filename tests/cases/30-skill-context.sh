#!/usr/bin/env bash
# Every `## Context` block runs !`…`-substituted shell at skill load time, and
# the harness aborts the whole skill if one of those commands exits non-zero.
#
# That is not a hypothetical. It is recorded in this plugin's CHANGELOG under
# 0.2.0: `init` could never run outside a repo and `commit` and `branch` broke
# in a repo with no commits, because `git rev-parse` and `git log` exit non-zero
# there. Every command now ends in a fallback, and these tests are what keep it
# that way — a skill about git has to load in a directory that is not yet a
# repository, which is the one state its `init` skill exists to fix.
. "$(dirname "$0")/../lib/harness.sh"

test_context_commands_outside_a_repo() {
  desc "every context command exits 0 outside a git repository"
  check_skills "$SKILLS_DIR" "a directory that is not a git repository"
}

test_context_commands_in_a_fresh_repo() {
  desc "every context command exits 0 in a repo with no commits"
  git_here
  check_skills "$SKILLS_DIR" "a git repository with no commits"
}

test_context_commands_in_a_repo_with_history() {
  desc "every context command exits 0 in a repo with commits, a tag and a dirty tree"
  git_here
  printf 'hello\n' > file.txt
  git add file.txt
  git commit -q -m "feat: first"
  git tag -a v0.1.0 -m "v0.1.0"
  printf 'more\n' >> file.txt
  git add file.txt
  git commit -q -m "fix: second"
  printf 'staged\n' > staged.txt
  git add staged.txt
  printf 'untracked\n' > untracked.txt
  check_skills "$SKILLS_DIR" "a git repository with commits, a tag and a dirty tree"
}

test_context_commands_in_a_repo_with_no_tags() {
  desc "every context command exits 0 in a repo with commits but no tags"
  # `git log $(git describe --tags --abbrev=0)..HEAD` degenerates to
  # `git log ..HEAD` when there is no tag to describe; the fallback has to
  # carry it. This is the state every project is in before its first release —
  # exactly when `versioning` and `release` are asked for.
  git_here
  printf 'hello\n' > file.txt
  git add file.txt
  git commit -q -m "feat: first"
  check_skills "$SKILLS_DIR" "a git repository with commits but no tags"
}

test_context_commands_in_a_detached_head() {
  desc "every context command exits 0 with a detached HEAD"
  # `git branch --show-current` prints nothing and exits 0 here, so the skill
  # loads with an empty current branch rather than an aborted context block.
  git_here
  printf 'hello\n' > file.txt
  git add file.txt
  git commit -q -m "feat: first"
  git checkout -q --detach HEAD
  check_skills "$SKILLS_DIR" "a git repository with a detached HEAD"
}

test_the_context_command_count_is_unchanged() {
  desc "the expected number of context commands is still present"
  # A count that drops silently means a `## Context` block was deleted; one that
  # jumps means new commands landed without being considered here.
  n=0
  for s in $(skill_files); do
    n=$((n + $(context_commands "$s" | grep -c .)))
  done
  assert_eq "$n" "35" "35 context commands across the six git-tools skills"
}

test_pipefail_fragile_commands_are_known() {
  desc "the set of context commands that would fail under pipefail is unchanged"
  # Four commands end in `| head` with no `|| echo` fallback. They exit 0
  # outside a repo only because a pipeline reports its last command's status.
  # If the skill harness ever ran context blocks with `set -o pipefail`, those
  # four would abort their skills. Nothing suggests it does — this test exists
  # so the number cannot creep up unnoticed, not because it is a bug today.
  fragile=""
  count=0
  for s in $(skill_files); do
    skill="$(basename "$(dirname "$s")")"
    while IFS= read -r cmd; do
      [ -n "$cmd" ] || continue
      bash -c "set -o pipefail; $cmd" >/dev/null 2>&1 && continue
      count=$((count + 1))
      fragile="${fragile:+$fragile }$skill"
      note "pipefail-fragile — $skill: $cmd"
    done <<EOF
$(context_commands "$s")
EOF
  done
  assert_eq "$count" "4" \
    "exactly four commands depend on pipeline status: 'git tag … | head -5' in changelog, versioning and release, plus 'git status -sb | head -1' in release"
  assert_eq "$(printf '%s' "$fragile" | tr ' ' '\n' | sort -u | tr '\n' ' ')" \
    "changelog release versioning " \
    "and they live in the three skills that read tags"
}

run_cases
