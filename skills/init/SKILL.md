---
name: init
allowed-tools: Bash(git init:*), Bash(git rev-parse:*), Bash(git status:*), Bash(git branch:*), Bash(git config:*), Bash(git check-ignore:*), Bash(ls:*), Bash(cat:*), Bash(head:*), Bash(echo:*), Read, Write, Edit
description: Initialize a git repository in the project root, confirming the base branch name and a starter .gitignore. Use when the user wants to put a project under version control, asks whether the project is a git repo yet, mentions 'git init', or says things like 'set up git here', 'this project has no git', 'start tracking this in git', 'make this a repo'. Also covers choosing the default/base branch name for a brand-new repo.
model: sonnet
---

# Init SKILL

## Context

- Project root: !`pwd`
- Repo toplevel (`(no repo)` means this directory is not in a git repo): !`git rev-parse --show-toplevel 2>/dev/null || echo "(no repo)"`
- Configured default branch: !`git config --get init.defaultBranch 2>/dev/null || echo "(unset)"`
- Root contents: !`ls -A`
- Editor and tool folders present (`(none)` means there is nothing to decide): !`ls -d .vscode .idea .zed .fleet .claude 2>/dev/null | grep . || echo "(none)"`
- Docs root managed by `pm`: !`find . -mindepth 2 -maxdepth 2 -name pm.config.json 2>/dev/null | sed 's|/pm.config.json$||; s|^\./||' | grep . || echo "(none)"`
- Existing .gitignore: !`head -40 .gitignore 2>/dev/null || echo "(none)"`

## Your task

Put the project root under git, or report that it already is.

### Step 1 — Establish repo state

Read the context above and settle on exactly one of three states:

| State | Signal | What to do |
|---|---|---|
| **Already a repo** | Repo toplevel equals the project root | Report the current branch and status, then stop — nothing to initialize |
| **Inside a parent repo** | Repo toplevel is an *ancestor* of the project root | Report the parent repo's path, then use **AskUserQuestion**: work in the parent repo, or create a nested repo here (warn that nesting confuses tooling and the parent will see this directory as untracked) |
| **No repo** | Toplevel is empty or the command errored | Continue to Step 2 |

Complete when the state is named out loud and, for the first two, the user has been told what it means.

### Step 2 — Confirm the base branch

Use **AskUserQuestion** to confirm the name of the base branch the repo starts on:

- `master` — the default, recommended
- `main`
- The value of `init.defaultBranch` from the context, when it is set and differs
  from the options above

The tool's built-in "Other" choice covers any name not listed — do not ask for one
in prose.

Complete when the user has picked or typed a name.

### Step 3 — Initialize

1. Run `git init -b <base-branch>`.
2. If that fails because the git version predates `-b`, run `git init`, then `git branch -m <base-branch>`.
3. Confirm with `git rev-parse --abbrev-ref HEAD` that HEAD points at the chosen name.

### Step 4 — Decide which tool folders git ignores

Editor and tool folders are the one part of a `.gitignore` that cannot be
inferred from the project type — whether `.vscode/` belongs to the team or to
the person is a decision, not a fact about the stack. Ask instead of guessing.

Skip this step when both the *editor and tool folders* and *docs root* context
lines say `(none)` — there is nothing to decide yet.

Use **AskUserQuestion**, one question, `multiSelect: true`: "Which of these
should git ignore?" One option per folder the context actually found — never
list a folder that is not there:

| Folder | Recommendation | Why |
|---|---|---|
| `.vscode/` | Track | Workspace settings — fonts, the window colour, task definitions — are the same for everyone working on the project |
| The `pm` docs root (`.pm/`, `.docs/`, …) | Track | PRDs, specs and decision logs are the project's writing; ignoring them means only the author ever reads them |
| `.claude/` | Track | Project skills, agents and hooks are shared setup; only `settings.local.json` inside it is personal |
| `.idea/`, `.zed/`, `.fleet/` | Ignore | Mostly per-user IDE state — window layout, caches, local run configs |

Mark the recommended choices in the option labels, and say in the question that
this only decides what the `.gitignore` says: ignoring a folder does not
un-track it once it has been committed.

Complete when the user has answered, even if the answer is "ignore none of them".

### Step 5 — Write or extend the .gitignore

**If the root already has a `.gitignore`** (the context shows its contents),
do not redraft it. Check whether each folder chosen in Step 4 is already covered
with `git check-ignore -q <folder>`, and offer to **append** only the lines that
are missing. Leave the rest of the file alone.

**If there is no `.gitignore`:**

1. Detect the project type from the root contents — `package.json` (Node), `pyproject.toml` / `requirements.txt` (Python), `Cargo.toml` (Rust), `go.mod` (Go), `Gemfile` (Ruby), `composer.json` (PHP), Xcode/Android project files, and so on. More than one may apply.
2. Read `${CLAUDE_PLUGIN_ROOT}/references/gitignore-patterns.md` for the categories worth ignoring — secrets, dependencies, build output, OS/editor cruft, logs and caches, large blobs. If that file cannot be read, fall back to the standard ignore set for the detected stacks.
3. Draft a `.gitignore` covering the categories that actually apply to this project, and check the root contents for anything already sitting there that matches (a stray `.DS_Store`, a `node_modules/`, a `.env`) so it is covered. The editor and tool folders come from Step 4's answer and from nowhere else — a folder the user chose to track must not appear in the draft, whatever the reference file says about it.
4. Show the drafted file and use **AskUserQuestion**: "Write it / Edit it / Skip .gitignore".
5. Write the file only after approval.

Complete when a `.gitignore` exists in the root or the user declined one.

### Step 6 — Report

State the repo root, the base branch, whether a `.gitignore` was written or appended to, and which tool folders it ignores. Point the user at `commit` for the first commit, suggest the first commit message to be `chore(git): repo init`.

## Integration

- **After this skill**: use `commit` to make the first conventional commit
- **Then**: use `branch` to start feature work off the base branch

## Rules

- Every decision the user has to make goes through **AskUserQuestion** — the nested-repo
  choice, the base branch, the tool folders, the `.gitignore`. Never ask in prose and wait
  for a typed reply
- Never run `git init` outside the project root
- Never overwrite an existing `.gitignore` — append to it or leave it alone
- Never put `.vscode/`, `.claude/` or the `pm` docs root into a `.gitignore` on your own
  judgement. Those three are commonly committed on purpose, and silently ignoring one
  hides work the user meant to share. Step 4's answer decides, always
- Never offer to stage or commit anything here. This skill decides what git *ignores*;
  what gets committed is `commit`'s job
- Initializing is the only write this skill makes on its own; staging and committing belong to `commit`

---

# Links

- [gitignore-patterns](../../references/gitignore-patterns.md)
