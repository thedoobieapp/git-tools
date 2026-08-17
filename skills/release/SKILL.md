---
name: release
allowed-tools: Bash(git log:*), Bash(git tag:*), Bash(git status:*), Bash(git describe:*), Bash(git diff:*), Bash(git add:*), Bash(git commit:*), Bash(git push:*), Bash(git rev-parse:*), Bash(git branch:*), Bash(echo:*), Read, Edit, Write
description: "Cut a release in one pass — decide the Semantic Versioning bump, promote the CHANGELOG Unreleased section, update every version file, commit and tag. Use whenever the user wants to release, cut a release, ship a version, or says 'release 1.2.0', 'cut a release', 'do a release', 'ship it', 'tag and release', 'prepare and publish the release', 'release this'. Combines what `versioning` and `changelog` do separately into a single confirmation, one `chore: release X.Y.Z` commit and one annotated tag."
model: sonnet
---

# Release SKILL

## Context

- Repo check (`(no repo)` means this directory is not under git): !`git rev-parse --show-toplevel 2>/dev/null || echo "(no repo)"`
- Current branch: !`git branch --show-current 2>/dev/null || echo "(no repo)"`
- Latest tags: !`git tag --sort=-version:refname 2>/dev/null | head -5`
- Commits since last tag: !`git log $(git describe --tags --abbrev=0 2>/dev/null)..HEAD --oneline --no-merges 2>/dev/null || git log --oneline -20 2>/dev/null || echo "(no commits yet)"`
- Git status: !`git status --short 2>/dev/null || echo "(no repo)"`
- Remote tracking: !`git status -sb 2>/dev/null | head -1`

## Your task

Take the repo from "work is done" to "version bumped, changelog written,
commit made, tag created" — with **one** confirmation from the user.

This skill owns the whole sequence. Do not invoke `versioning` or `changelog`;
they cover the same ground standalone and running them here produces duplicate
prompts and a split commit.

### Step 0 — Confirm there is a repo

If the repo check in the context reads `(no repo)`, this directory is not under
version control. Say so, point the user at `init` to create the repo, and stop —
nothing below applies until there is one.

### Step 1 — Preflight

Establish that a release is possible before drafting anything:

1. **Uncommitted changes** — if `git status --short` is non-empty, list the files
   and use **AskUserQuestion**: "Include them in the release commit / Commit them
   separately first (stop here) / Cancel". Never sweep unknown changes into a
   release commit silently.
2. **Branch** — if the current branch is not the base branch (`master`/`main`) and
   not a `release/*` branch, say so and use **AskUserQuestion**: "Release from this
   branch / Cancel (switch branches first)".
3. **Commits to release** — if there are no commits since the last tag, report that
   and stop. There is nothing to release.

Complete when the working tree's fate is decided and there is at least one
commit to release.

### Step 2 — Determine the version

Read `${CLAUDE_PLUGIN_ROOT}/skills/docs/version-sources.md`.

1. Detect the current version and **every** file that carries it — the first match
   is authoritative, but all of them get updated.
2. Count the commits since the last tag by conventional type and apply the bump
   table. Note the `0.x` rule when it applies.
3. If the user named a version or bump type in their request, use that instead.

Hold the result: current version, new version, bump type, one-line reasoning
(e.g. "1 feat, 0 fix, 0 breaking"), and the list of files to update.

### Step 3 — Draft the changelog section

Read `${CLAUDE_PLUGIN_ROOT}/skills/docs/commit-type-mapping.md`
and `${CLAUDE_PLUGIN_ROOT}/skills/docs/keep-a-changelog-1.1.0.md`.

1. If `CHANGELOG.md` does not exist, create the Keep a Changelog skeleton in memory
   and treat every commit since the repo's first as the release's content.
2. Start from whatever already sits under `## [Unreleased]` — those entries were
   written deliberately and are the source of truth.
3. Cross-check against the commits since the last tag. Anything user-visible that
   landed without an Unreleased entry gets drafted now; mention that you added it.
4. Categorize, and write the entries as human-facing descriptions.
5. Date the section with **today's date** in ISO 8601 (`YYYY-MM-DD`). Get it from
   the environment context, not from a guess.

Do not write to the file yet.

### Step 4 — Confirm, once

Print the plan first — current → new version, the files that will be updated, and
the drafted changelog section in full. Then use a **single AskUserQuestion** call
carrying these questions together:

| Header | Question | Options |
|---|---|---|
| Version | `X.Y.Z` → `A.B.C` (*bump*) — *reasoning* | **Go for it** / Change version / Cancel |
| Changelog | The drafted section, as shown above | **Looks good** / Edit entries |
| Push | Push the commit and tag to the remote afterwards? | **No, local only** / Yes, push |

Bolded options are the defaults — list them first. **"No, local only" is the
default for Push**: a tag that has been fetched by someone else cannot be
retracted cleanly.

If the user picks "Change version" or "Edit entries", apply their input and
re-confirm. Nothing is written until this step returns approval.

### Step 5 — Apply

In this order, so the tag lands on a commit that contains everything:

1. **Version files** — update every file from Step 2 to the new version.
2. **CHANGELOG.md** — insert `## [A.B.C] - YYYY-MM-DD` below `## [Unreleased]`,
   move the entries into it, and leave `## [Unreleased]` in place and empty.
   Update link-reference definitions at the bottom of the file if the changelog
   uses them.
3. **Commit** — stage the version files, `CHANGELOG.md`, and anything the user
   opted to include in Step 1, then commit as:

   ```
   chore: release A.B.C
   ```

   Verify with `git status --short` that nothing intended for the release was
   left unstaged before moving on.
4. **Tag** — annotated, on that commit:

   ```bash
   git tag -a vA.B.C -m "Release vA.B.C"
   ```

### Step 6 — Push, only if asked

If the user chose to push in Step 4:

```bash
git push && git push --tags
```

Otherwise print that exact command and say the release is local until it runs.

### Step 7 — Report

State plainly:

- Version: current → new
- Files updated
- Commit SHA and subject
- Tag created
- Pushed, or still local (with the command to push)

If any step was skipped or failed, say which and why. Do not report a release as
done when the tag or commit did not land.

## Integration

- **Before this skill**: `commit` — conventional commits are what the bump and the
  changelog entries are derived from ([commit](../commit/SKILL.md))
- **Replaces**: running `changelog` (Release mode) and then `versioning` by hand ([changelog](../changelog/SKILL.md), [versioning](../versioning/SKILL.md))
- **Still use `versioning`** on its own to bump a version without cutting a release ([versioning](../versioning/SKILL.md))
- **Still use `changelog`** on its own to add entries to `## [Unreleased]` as you work ([changelog](../changelog/SKILL.md))
- **Pairs with**: `branch` — `release/vX.Y.Z` when a release needs its own branch ([branch](../branch/SKILL.md))

## Rules

- One confirmation, one commit, one tag — never split the release across commits
- Every decision the user has to make goes through **AskUserQuestion** — the dirty
  tree, the branch, the version, the changelog, the push. Never ask in prose and
  wait for a typed reply
- Never tag a commit that does not contain the changelog entry for that version
- Never push without explicit approval in Step 4
- Never re-use an existing tag; if `vA.B.C` already exists, stop and report it
- Every version-carrying file moves together — a repo with `plugin.json` and
  `marketplace.json` out of sync is a bug this skill must not create
- Dates are ISO 8601 (`YYYY-MM-DD`), taken from the environment
- If a `${CLAUDE_PLUGIN_ROOT}/skills/docs/…` file cannot be read, find it under the
  plugin's `skills/docs/` directory and read it there. Never guess a bump or a
  changelog format because a reference did not load — say what failed and stop
- NEVER include co-authoring or attribution references in commits

---

# Links

- [version-sources](../docs/version-sources.md)
- [commit-type-mapping](../docs/commit-type-mapping.md)
- [keep-a-changelog-1.1.0](../docs/keep-a-changelog-1.1.0.md)
