---
name: commit
allowed-tools: Bash(git add:*), Bash(git status:*), Bash(git commit:*), Bash(git log:*), Bash(git diff:*), Bash(git check-ignore:*), Bash(git restore:*), Bash(git ls-files:*), Bash(git branch:*), Bash(git rev-parse:*), Bash(echo:*), Read, Edit, Write
description: Create conventional git commits with proper type, scope, and message. Use when committing staged changes, writing commit messages, preparing commits for review, or when the user says 'commit this', 'commit my changes', 'save my work', 'create a commit', or 'what should the commit message be'.
model: sonnet
---

# Commit SKILL

## Context

- Repo check (`(no repo)` means this directory is not under git): !`git rev-parse --show-toplevel 2>/dev/null || echo "(no repo)"`
- Current git status: !`git status 2>/dev/null || echo "(no repo)"`
- Current git diff (staged and unstaged changes): !`git diff HEAD 2>/dev/null || git diff --cached 2>/dev/null || echo "(no repo)"`
- Current branch: !`git branch --show-current 2>/dev/null || echo "(no repo)"`
- Recent commits: !`git log --oneline -10 2>/dev/null || echo "(no commits yet — this would be the first)"`
- Staged files: !`git diff --cached --name-only 2>/dev/null || echo "(no repo)"`
- Untracked (not yet ignored): !`git ls-files --others --exclude-standard 2>/dev/null || echo "(no repo)"`

## Your task

### Step 0 — Confirm there is a repo

If the repo check in the context reads `(no repo)`, this directory is not under
version control. Say so, point the user at `init` to create the repo, and stop —
nothing below applies until there is one.

### Step 1 — Identify changes

1. Check for staged changes — these are the primary commit candidates
2. If no staged changes exist, check for unstaged changes
3. If **both** staged and unstaged changes exist, use **AskUserQuestion**: "Commit
   the staged files only / Include the unstaged changes too". Do not decide this
   silently — it changes what lands in the commit
4. If no changes at all, inform the user and stop

### Step 2 — Screen for files that shouldn't be committed

Before drafting a message, screen the files about to enter the commit so nothing that belongs outside the repo (secrets, dependencies, build output, OS/editor cruft) slips in. This screen focuses on **newly added / untracked files** — `.gitignore` cannot un-track a file that is already tracked in git.

1. Build the candidate set: **staged files** + **untracked-not-ignored files** (the latter get staged in the final step, so they count).
2. Compare each candidate against the categories in `${CLAUDE_PLUGIN_ROOT}/skills/docs/gitignore-patterns.md` and flag secrets, dependency directories, build output, OS/editor cruft, logs/caches, and unusually large or binary blobs. Run `git check-ignore <path>` to avoid re-flagging anything already ignored.
3. If nothing is flagged, continue to the next step silently.
4. If files are flagged, list them (grouped by reason) and use **AskUserQuestion** to let the user choose what to do per group:
   - **Add to .gitignore** — append the appropriate pattern to `.gitignore` (create the file if missing), then unstage the file with `git restore --staged <path>`
   - **Unstage only** — `git restore --staged <path>`, leaving `.gitignore` untouched
   - **Commit anyway** — keep the file in the commit
   - **Abort** — stop without committing
5. Apply the chosen actions, then proceed.

### Step 3 — Group changes into commits

**Start from one commit for the entire working set.** That is the answer unless a split earns its place. A commit spans as many files as the change touches — a feature and its tests, types, and docs are *one* commit, not four. File count is irrelevant; the change is the unit.

Add a second commit only when a part **fails the together test**: would a reviewer be confused seeing these edits in the same commit, or might someone want to revert one part without the other? If neither is true, it stays in the one commit. Applying two unrelated conventional-commit *types* to the same work (a real `fix` living inside a `feat`) is the usual case that fails the test — but the burden is on the split to justify itself, not on the single commit.

Do **not** split by file, by directory, by type label, or "for cleaner history." Those are not reasons; the together test is the only reason.

Completion: you have the smallest number of groups where every group passes the together test, and every changed file (staged + to-be-staged) sits in exactly one of them.

### Step 4 — Draft the commit message(s)

Draft one message per group from Step 3, each following `${CLAUDE_PLUGIN_ROOT}/skills/docs/conventional-commits-1.0.0.md`

**Choosing the type:**

| Type | When to use |
| --- | --- |
| `feat` | New feature or capability |
| `fix` | Bug fix |
| `docs` | Documentation only |
| `style` | Formatting, whitespace (no logic change) |
| `refactor` | Code restructuring (no feature/fix) |
| `perf` | Performance improvement |
| `test` | Adding or updating tests |
| `build` | Build system or dependencies |
| `ci` | CI/CD configuration |
| `chore` | Maintenance tasks |
| `revert` | Reverting a previous commit |

**Adding scope** (optional but recommended when changes are localized):

Use a noun in parentheses describing the section of the codebase:

```text
feat(auth): add OAuth2 login flow
fix(parser): handle empty arrays correctly
docs(api): update endpoint descriptions
```

**Breaking changes** — use `!` after the type/scope when the commit introduces a breaking API change:

```text
feat(api)!: change response format to JSON:API

BREAKING CHANGE: all endpoints now return JSON:API envelopes instead of plain objects
```

**Multi-line commits** — add a body and/or footers when the "why" isn't obvious from the description alone:

```text
fix(db): use connection pooling for queries

The previous approach opened a new connection per query, causing connection exhaustion under load.

Refs: #142
```

**Message rules:**

- Description line: imperative mood, lowercase, no period, max 72 chars
- Body: wrap at 72 chars, explain *why* not *what*
- Footers: `BREAKING CHANGE:`, `Refs:`, `Closes:`, `Fixes:`
- Do not add "Co-Authored-By:", "Claude" or similar attributions

### Step 5 — Confirm with user

Confirm via **AskUserQuestion**, **one commit message per question** — this is the
only way this skill takes approval, never a plain-text "shall I commit?":

1. One question per drafted commit, showing that commit's full message as visible question text (a preview panel is not a substitute), with options "Send it! / Edit message / Abort".
2. One final question confirming the commit branch.

A single AskUserQuestion call carries at most 4 questions — with more commits than that, batch across successive calls. Complete when every drafted commit has been approved, edited, or aborted through its own question.

### Step 6 — Execute the commits

Commit each approved group in turn. For each group:

1. Stage exactly that group's files (`git add <paths>`), so unrelated changes stay out of this commit.
2. Commit using a HEREDOC to preserve multi-line formatting:

```bash
git commit -m "$(cat <<'EOF'
<type>[(<scope>)][!]: <description>

[optional body]

[optional footer(s)]
EOF
)"
```

## Rules

- Always validate the commit message with the user before committing, through
  **AskUserQuestion** — the flagged-file screen, each drafted message, the branch.
  Never ask in prose and wait for a typed reply
- If the user picks "Edit message", apply their input and re-ask that commit's
  question. Nothing is committed until every group has been approved
- Match the style of recent commits in the repository when possible
- NEVER include co-authoring or attribution references in commits

---

# Links

- [conventional-commits-1.0.0](../docs/conventional-commits-1.0.0.md)
- [init](../init/SKILL.md)
- [gitignore-patterns](../docs/gitignore-patterns.md)
