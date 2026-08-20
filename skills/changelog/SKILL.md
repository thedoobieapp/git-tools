---
name: changelog
allowed-tools: Bash(git log:*), Bash(git tag:*), Bash(git status:*), Bash(git diff:*), Bash(git describe:*), Bash(git branch:*), Bash(git rev-parse:*), Bash(echo:*), Read, Edit, Write
description: Create or update CHANGELOG.md following the Keep a Changelog 1.1.0 format. Use this skill whenever the user mentions changelog, release notes, tracking changes, documenting changes, updating CHANGELOG.md, preparing a release, or wants to know what changed between versions. Also triggers for phrases like 'update the changelog', 'what changed since last release', 'add to changelog', 'prepare release notes', 'create a changelog', 'document the changes', 'log the changes'. Handles creating new changelogs, adding entries to Unreleased, and promoting Unreleased to a versioned release.
model: sonnet
---

# Changelog SKILL

## Context

- Repo check (`(no repo)` means this directory is not under git): !`out=$(git rev-parse --show-toplevel 2>/dev/null) || true; echo "${out:-(no repo)}"`
- Current branch: !`out=$(git branch --show-current 2>/dev/null) || true; echo "${out:-(no branch — detached HEAD, or no repo)}"`
- Latest tags: !`out=$(git tag --sort=-version:refname 2>/dev/null | head -5) || true; echo "${out:-(no tags yet)}"`
- Git status: !`out=$(git status --short 2>/dev/null) || true; echo "${out:-(working tree clean)}"`

## Your task

Maintain CHANGELOG.md following `${CLAUDE_PLUGIN_ROOT}/skills/changelog/references/keep-a-changelog-1.1.0.md` conventions.

### Step 0 — Confirm there is a repo

If the repo check in the context reads `(no repo)`, this directory is not under
version control. Say so, point the user at `init` to create the repo, and stop —
nothing below applies until there is one.

### Step 1 — Detect mode

Determine what the user wants:

1. **Create** — No CHANGELOG.md exists yet → create one from scratch
2. **Update** — Add entries to the `## [Unreleased]` section
3. **Release** — Move Unreleased entries into a new versioned section

If unclear, use **AskUserQuestion** to pick the mode — offer Create / Update /
Release as options with a one-line description of each, recommending the one the
repo state points at (no CHANGELOG.md → Create; entries pending and a version
bump in the request → Release; otherwise Update).

### Step 2 — Gather changes

Identify the range of commits to document:

```bash
# Find the last tag (version anchor)
git describe --tags --abbrev=0 2>/dev/null

# Get commits since last tag (or all commits if no tags)
git log <last-tag>..HEAD --oneline --no-merges
```

If the range is ambiguous — no tags exist, or the user hinted at a narrower scope —
use **AskUserQuestion** to settle it: everything since the last tag, everything
since the repo's first commit, or a range the user names.

### Step 3 — Categorize entries

Group changes into the six standard categories, mapping conventional commit types
with the table in
`${CLAUDE_PLUGIN_ROOT}/skills/changelog/references/commit-type-mapping.md`.

Write entries as human-readable descriptions — not raw commit messages. Each entry should explain what changed from a user's perspective.

### Step 4 — Draft and confirm

Print the drafted section in full first — the entries must be visible as message
text, a question preview panel is not a substitute. Then confirm with
**AskUserQuestion**:

- Show each category with its entries
- For **Release** mode, also show the version number and today's date
- Offer options: "Looks good! / Edit entries / Cancel"

If the user picks "Edit entries", apply their input and re-ask. Nothing is written
to `CHANGELOG.md` until this step returns approval.

### Step 5 — Write the changelog

#### Create mode

If no CHANGELOG.md exists, create it with this structure:

```markdown
# Changelog

All notable changes to this project will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.1.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [Unreleased]

### Added
- ...
```

#### Update mode

Add entries under `## [Unreleased]`, creating category subsections as needed. Preserve existing entries — append new ones.

#### Release mode

1. Create a new versioned section below `## [Unreleased]`:

   ```markdown
   ## [X.Y.Z] - YYYY-MM-DD
   ```

2. Move all Unreleased entries into the new versioned section
3. Leave `## [Unreleased]` empty above it (ready for new entries)
4. Use ISO 8601 date format (YYYY-MM-DD)

## Integration

- **Pairs with**: `commit` — conventional commit types make changelog categorization straightforward ([commit](../commit/SKILL.md))
- **Pairs with**: `versioning` — run `versioning` to bump the version, then `changelog` in release mode to document it (or vice versa) ([versioning](../versioning/SKILL.md))
- **Use `release` instead** for Release mode — it promotes the Unreleased section,
  bumps every version file, commits and tags in one pass. Create and Update mode
  remain this skill's job. [release](../release/SKILL.md)

## Rules

- Every decision the user has to make goes through **AskUserQuestion** — mode,
  commit range, the drafted entries. Never ask in prose and wait for a typed reply
- Dates must be ISO 8601 format (YYYY-MM-DD)
- Latest version always comes first
- Never remove existing changelog entries without explicit user request
- Always keep an `[Unreleased]` section at the top
- Entries are for humans — translate commit messages into clear, user-facing descriptions
- Only include categories that have entries (don't add empty sections)
- Any git command you run during the task must be written so a non-zero exit
  cannot abort the step. Use `out=$(<command> 2>/dev/null) || true; echo "${out:-(marker)}"`,
  the same form the context block uses. Several git commands report an ordinary,
  expected answer through a non-zero status — `check-ignore` exits `1` for "not
  ignored", `config --get` exits `1` for "unset", `config --unset` exits `5` for
  "was not set", `rev-parse HEAD` exits `128` on a repo with no commits — and an
  unguarded one of those reads as a crash and stops work that should have
  continued
- Do not re-run a context command just to confirm what is already printed above.
  Do re-check when its output contradicts itself or carries a shell error — a
  wrong answer is worth verifying — but re-run it in the guarded form, never
  bare, or the check fails the same way the original did
- Never put an unquoted glob (`README*`, `*.md`) in a command. Shells disagree
  about an unmatched one: bash and `sh` pass it through literally, zsh aborts the
  whole command before it runs and prints `no matches found` — which no `2>/dev/null`
  can suppress, because the shell emits it during expansion rather than the
  command emitting it. The result is a confident wrong answer. List the directory
  and filter it instead: `ls -A | grep -iE "^(readme|license)"`

---
# Links

- [keep-a-changelog-1.1.0](references/keep-a-changelog-1.1.0.md)
- [commit-type-mapping](references/commit-type-mapping.md)
