---
name: versioning
allowed-tools: Bash(git log:*), Bash(git tag:*), Bash(git status:*), Bash(git describe:*), Bash(git add:*), Bash(git commit:*), Bash(git branch:*), Bash(git rev-parse:*), Bash(echo:*), Read, Edit, Write
description: Manage project version numbers following Semantic Versioning 2.0.0. Use this skill whenever the user wants to bump a version, create a release, tag a version, check the current version, determine the next version, or prepare a release. Also triggers for phrases like 'bump version', 'what should the next version be', 'release v1.2.0', 'tag this version', 'update version', 'prepare for release', 'major/minor/patch bump', 'increment the version'. Detects versions from package.json, Cargo.toml, pyproject.toml, and other project files, suggests bump type based on conventional commits, and creates git tags.
model: sonnet
---

# Versioning SKILL

## Context

- Repo check (`(no repo)` means this directory is not under git): !`out=$(git rev-parse --show-toplevel 2>/dev/null) || true; echo "${out:-(no repo)}"`
- Current branch: !`out=$(git branch --show-current 2>/dev/null) || true; echo "${out:-(no branch — detached HEAD, or no repo)}"`
- Latest tags: !`out=$(git tag --sort=-version:refname 2>/dev/null | head -5) || true; echo "${out:-(no tags yet)}"`
- Recent commits since last tag: !`out=$(git log $(git describe --tags --abbrev=0 2>/dev/null)..HEAD --oneline --no-merges 2>/dev/null || git log --oneline -10 2>/dev/null) || true; echo "${out:-(no commits yet)}"`
- Git status: !`out=$(git status --short 2>/dev/null) || true; echo "${out:-(working tree clean)}"`

## Your task

Manage version numbers following `${CLAUDE_PLUGIN_ROOT}/skills/versioning/references/semantic-versioning-2.0.0.md` conventions.

### Step 0 — Confirm there is a repo

If the repo check in the context reads `(no repo)`, this directory is not under
version control. Say so, point the user at `init` to create the repo, and stop —
nothing below applies until there is one.

### Step 1 — Detect current version

Look for the project version in the locations listed in
`${CLAUDE_PLUGIN_ROOT}/skills/versioning/references/version-sources.md` —
first match wins, but every other file carrying a version still gets updated.

If no version is found, use **AskUserQuestion** to establish the starting point —
offer `0.1.0` (recommended for a new project), `1.0.0`, and the latest git tag when
one exists, so the user can pick rather than type.

Report the detected version and its source file to the user.

### Step 2 — Analyze commits for bump suggestion

Review conventional commits since the last version tag and apply the bump table in
`${CLAUDE_PLUGIN_ROOT}/skills/versioning/references/version-sources.md`.

Present a summary:

- Number of feat / fix / breaking / other commits
- Recommended bump type with reasoning
- The resulting version number (current → new)

If the user specified an explicit version or bump type, use that instead of the suggestion.

### Step 3 — Confirm with user

Print the plan first — current → new version, the bump reasoning, and the full list
of files that will be updated. Then use a **single AskUserQuestion** call carrying
these questions together:

| Header | Question | Options |
|---|---|---|
| Version | `X.Y.Z` → `A.B.C` (*bump*) — *reasoning* | **Go for it** / Change version / Cancel |
| Commit | Create a commit? (`chore: bump version to A.B.C`) | **Yes** / No, leave the files unstaged |
| Tag | Create an annotated tag `vA.B.C`? | **Yes** / No |

Bolded options are the defaults — list them first. If the user picks "Change
version", apply their input and re-ask. Nothing is written until this step returns
approval.

Afterwards, suggest: "Run `changelog` to document the changes for this release."

### Step 4 — Apply version bump

1. Update the version in all detected project files (same files from Step 1)
2. If user chose to commit:
   - Stage the changed files
   - Create a commit: `chore: bump version to X.Y.Z`
3. If user chose to create a tag:
   - Create an annotated git tag: `git tag -a vX.Y.Z -m "Release vX.Y.Z"`
   - If the user did NOT commit (files unstaged), warn that the tag will point to the current HEAD, not to a version-bump commit

### Step 5 — Report and suggest next steps

Report what was done:

- Files updated
- Commit created (or skipped)
- Tag created (or skipped)

Suggest next steps:

- "Run `changelog` to update CHANGELOG.md for this release" (if not already done)
- "Push with tags: `git push && git push --tags`"

## Integration

- **Pairs with**: `commit` — conventional commit types determine the version bump ([commit](../commit/SKILL.md))
- **Pairs with**: `changelog` — after bumping version, update the changelog with release notes ([changelog](../changelog/SKILL.md))
- **Pairs with**: `branch` — release branches follow `release/vX.Y.Z` naming ([branch](../branch/SKILL.md))
- **Use `release` instead** when cutting an actual release — it does the bump, the
  changelog and the tag in one confirmation and one commit. This skill is for
  bumping a version on its own.

## Rules

- Always confirm before modifying files or creating tags, and always through
  **AskUserQuestion** — starting version, target version, commit, tag. Never ask in
  prose and wait for a typed reply
- Never create tags on dirty working directories without warning the user
- Pre-release versions (e.g., `1.0.0-alpha.1`) are valid — support them if requested
- If on major version 0, remind the user that the API is considered unstable per SemVer
- NEVER include co-authoring or attribution references in commits
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

- [version-sources](references/version-sources.md)
- [semantic-versioning-2.0.0](references/semantic-versioning-2.0.0.md)
