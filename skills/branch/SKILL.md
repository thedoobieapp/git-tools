---
name: branch
allowed-tools: Bash(git branch:*), Bash(git checkout:*), Bash(git switch:*), Bash(git status:*), Bash(git log:*), Bash(git rev-parse:*), Bash(echo:*), Read
description: Create and switch to a new git branch following Conventional Branch naming conventions. Use this skill whenever the user wants to create a branch, start new work, begin a feature, fix a bug, prepare a hotfix, prepare a release, or mentions branch naming. Also triggers for phrases like 'start working on X', 'new branch for X', 'create a feature branch', 'I need to fix X', 'branch for X', 'prepare release X', 'checkout a new branch'. Covers branch creation, naming validation, and type selection (feat/, fix/, hotfix/, release/, chore/).
model: sonnet
---

# Branch SKILL

## Context

- Repo check (`(no repo)` means this directory is not under git): !`git rev-parse --show-toplevel 2>/dev/null || echo "(no repo)"`
- Current branch: !`git branch --show-current 2>/dev/null || echo "(no repo)"`
- Existing branches: !`git branch --list 2>/dev/null || echo "(no repo)"`
- Recent commits: !`git log --oneline -5 2>/dev/null || echo "(no commits yet)"`
- Git status: !`git status --short 2>/dev/null || echo "(no repo)"`

## Your task

Create a properly named git branch following `${CLAUDE_PLUGIN_ROOT}/references/conventional-branch-1.0.0.md` conventions.

### Step 0 — Confirm there is a repo

If the repo check in the context reads `(no repo)`, this directory is not under
version control. Say so, point the user at `init` to create the repo, and stop —
nothing below applies until there is one.

### Step 1 — Determine branch type

Analyze the user's request to determine the appropriate branch prefix:

| Prefix      | When to use                                |
|-------------|--------------------------------------------|
| `feat/`     | New feature or capability                  |
| `fix/`      | Bug fix                                    |
| `hotfix/`   | Urgent fix for production                  |
| `release/`  | Preparing a versioned release              |
| `chore/`    | Non-code tasks (deps, docs, CI, cleanup)   |

If the user's intent is ambiguous, use **AskUserQuestion** to settle it — list the
plausible prefixes as options, most likely first, each with a one-line explanation
of why it fits. Never guess a prefix silently.

### Step 2 — Compose branch name

Build the branch name as `<type>/<description>`:

1. Use lowercase alphanumerics and hyphens only (dots allowed in release versions)
2. No consecutive, leading, or trailing hyphens or dots
3. Keep it concise but descriptive
4. Include ticket numbers when the user mentions them (e.g., `feat/issue-123-add-login`)

**Examples:**

- "Add a search feature" → `feat/add-search`
- "Fix the login bug from ticket #42" → `fix/issue-42-login-bug`
- "Update dependencies" → `chore/update-dependencies`
- "Prepare release 2.1.0" → `release/v2.1.0`
- "Critical security patch" → `hotfix/security-patch`

### Step 3 — Confirm with user

Confirm with **AskUserQuestion** — this is the only way this skill takes approval,
never a plain-text "shall I?":

- Show the proposed branch name
- Show the base branch it will be created from (current branch)
- Offer options: "Create it! / Change name / Change type / Cancel"

If the user picks "Change name" or "Change type", apply their input and re-ask.
Nothing is created until this step returns approval.

### Step 4 — Create and switch

1. Check for uncommitted changes — if the working directory is dirty, list the files
   and use **AskUserQuestion**: "Create the branch anyway (changes carry over) /
   Cancel and deal with them first".
2. If a branch with the same name already exists, use **AskUserQuestion** to offer
   the alternatives: switch to the existing branch, use a suffixed name (`-2`,
   ticket number), or cancel. Never force-create over an existing branch.
3. Create the branch: `git switch -c <branch-name>`
4. Confirm success with the new branch name

## Integration

- **Before this skill**: Make sure you're on the right base branch
- **After this skill**: Use `commit` to make conventional commits on the new branch ([commit](../commit/SKILL.md))
- **End of work**: Use `close-task` to merge, PR, or cleanup

## Rules

- Always validate branch names against the spec before creating
- Every decision the user has to make goes through **AskUserQuestion** — branch
  type, final name, dirty tree, name collision. Never ask in prose and wait for a
  typed reply
- Never force-create branches that overwrite existing ones without explicit confirmation
- NEVER include co-authoring or attribution references

---

# Links

- [conventional-branch-1.0.0](../../references/conventional-branch-1.0.0.md)
