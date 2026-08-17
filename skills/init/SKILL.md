---
name: init
allowed-tools: Bash(git init:*), Bash(git rev-parse:*), Bash(git status:*), Bash(git branch:*), Bash(git remote:*), Bash(git ls-remote:*), Bash(git config:*), Bash(git check-ignore:*), Bash(ls:*), Bash(cat:*), Bash(head:*), Bash(echo:*), Read, Write, Edit
description: Initialize a git repository in the project root, confirming the base branch name, the remote it will be pushed to, and a starter .gitignore. Use when the user wants to put a project under version control, asks whether the project is a git repo yet, mentions 'git init', or says things like 'set up git here', 'this project has no git', 'start tracking this in git', 'make this a repo', 'add the remote', 'point this repo at GitHub'. Also covers choosing the default/base branch name for a brand-new repo and wiring up origin.
model: sonnet
---

# Init SKILL

## Context

- Project root: !`pwd`
- Repo toplevel (`(no repo)` means this directory is not in a git repo): !`git rev-parse --show-toplevel 2>/dev/null || echo "(no repo)"`
- Remotes of that repo (`(none)` means no remote is configured): !`git remote -v 2>/dev/null | grep . || echo "(none)"`
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
| **Already a repo** | Repo toplevel equals the project root | Report the current branch and status. If the *Remotes* line reads `(none)`, ask **only** the Remote question from Step 2 — not the branch, not the folders, not the `.gitignore` — and if a URL comes back, run the check and the `git remote add` from Step 3. Then stop — there is nothing else to initialize |
| **Inside a parent repo** | Repo toplevel is an *ancestor* of the project root | Report the parent repo's path, then use **AskUserQuestion**: work in the parent repo, or create a nested repo here (warn that nesting confuses tooling and the parent will see this directory as untracked) |
| **No repo** | Toplevel is empty or the command errored | Continue to Step 2 |

The *Remotes* line describes whatever repo the *Repo toplevel* line names. In the
**Inside a parent repo** state those are the parent's remotes, not this
directory's — a nested repo created here starts with none, whatever that line
says.

A repo that already lists a remote is finished. Say what `origin` points at and
stop: never rewrite, re-point, rename or offer to replace a remote that is
already there.

Complete when the state is named out loud and, for the first two, the user has been told what it means. For a repo that already exists, that includes what `origin` points at, or that there is none.

### Step 2 — Confirm everything, once

Every answer this skill needs is knowable from the context block, and none of
them depends on another, so all of them are asked before anything is created.
Use a **single AskUserQuestion** call carrying these questions:

| Header | Question | Options | Included when |
|---|---|---|---|
| Branch | What should the base branch be called? | **`master`** / `main` / the value of `init.defaultBranch` from the context, when it is set and differs from those two | always |
| Remote | Where will this repo be pushed? Type the URL into "Other" — neither option below is one | **Skip — no remote for now** / I have a URL — type it in Other | always |
| Ignore | Which of these should git ignore? (`multiSelect: true`) | one per folder the context actually found — see below | the *editor and tool folders* or *docs root* line found something |
| Gitignore | This project has no `.gitignore`. Write one? | **Write it — the report shows it in full** / Show me the draft first / Skip the `.gitignore` | the *existing .gitignore* line reads `(none)` |

Bolded options are the defaults — list them first. Four is the tool's cap: when
Ignore and Gitignore are both included the call is full, and anything further
would have to split into a second one.

The tool's built-in "Other" choice covers any name not listed — do not ask for one
in prose. That holds for both free-text questions: the branch name and the remote
URL are typed there or not at all.

Nothing on disk is consulted for the URL. Do not read `package.json`, a
`Cargo.toml`, a `gh` config, the directory name or a parent repo's remote to
propose one — a wrong remote is worse than no remote, and this is the one fact
only the user has.

If the user picks "I have a URL" without typing one, ask the remote question
again on its own and say plainly that the URL goes in the "Other" box. Never
carry on with a guess, and never take the URL through prose.

Skipping is a complete answer, not a deferral. A repo with no remote works, and
Step 5 prints the command that adds one later.

**The Ignore options.** Editor and tool folders are the one part of a
`.gitignore` that cannot be inferred from the project type — whether `.vscode/`
belongs to the team or to the person is a decision, not a fact about the stack.
Ask instead of guessing. One option per folder the context found, and **never
list a folder that is not there**:

| Folder | Recommendation | Why |
|---|---|---|
| `.vscode/` | Track | Workspace settings — fonts, the window colour, task definitions — are the same for everyone working on the project |
| The `pm` docs root (`.pm/`, `.docs/`, …) | Track | PRDs, specs and decision logs are the project's writing; ignoring them means only the author ever reads them |
| `.claude/` | Track | Project skills, agents and hooks are shared setup; only `settings.local.json` inside it is personal |
| `.idea/`, `.zed/`, `.fleet/` | Ignore | Mostly per-user IDE state — window layout, caches, local run configs |

Mark the recommended choices in the option labels, and say in the question that
this only decides what the `.gitignore` says: ignoring a folder does not
un-track it once it has been committed.

**The Gitignore question** decides whether Step 4 may write the file without
showing it first. "Write it" is the default because the report prints the whole
file afterwards — nothing lands unseen, it is just seen after rather than before.
Do not ask it when a `.gitignore` already exists: the only write in that case is
appending the folders the Ignore question just collected, and that answer is its
own approval.

Complete when a branch name is settled, the remote question has an answer — a URL
or a deliberate skip — and each question that was included has been answered.

### Step 3 — Initialize

1. Run `git init -b <base-branch>`.
2. If that fails because the git version predates `-b`, run `git init`, then `git branch -m <base-branch>`.
3. Confirm with `git rev-parse --abbrev-ref HEAD` that HEAD points at the chosen name.

**If Step 2 produced no URL**, the step ends here. A local repo is a finished
repo.

**If it produced one**, check it before wiring it up, so nothing is written on a
URL nobody has looked at:

```bash
git ls-remote --exit-code <url>
```

That exits **0** when the remote answered and already carries refs, **2** when it
answered and is empty — the normal state of a repository created on the host a
few minutes ago — and anything else means it could not be reached. Treat 0 and 2
as reachable.

**Reachable** — run `git remote add origin <url>`, then `git remote -v` to show
what landed. On exit 0 the remote is not empty; say so, because the first push
will have two histories to reconcile.

**Unreachable** — do not add it quietly, and do not abort on it. Show the URL and
git's own error, then use **AskUserQuestion**:

| Header | Question | Options |
|---|---|---|
| Remote | `<url>` did not answer — *git's error, first line* | **Add it anyway** / Re-enter the URL in Other / Skip the remote |

Bolded options are the defaults — list them first. **"Add it anyway" is the
default**: the usual reasons a fresh remote stays silent are that the repository
has not been created on the host yet, or that credentials are not set up in this
shell. Neither makes the URL wrong, and neither is something this skill can tell
apart from a typo. On "Re-enter", take the new URL from "Other" and run the check
again — twice at most, then offer only "Add it anyway" or "Skip the remote".

Complete when HEAD is on the chosen branch and, if a URL was given, `origin`
points at it or the user decided to leave it off.

### Step 4 — Write or extend the .gitignore

Step 2 already settled this. Nothing here asks a fresh question unless the user
chose to see the draft first.

**If the root already has a `.gitignore`** (the context shows its contents), do
not redraft it. Check whether each folder chosen in Step 2 is already covered
with `git check-ignore -q <folder>`, and **append** only the lines that are
missing. Leave the rest of the file alone, and report the appended lines
verbatim. Do not ask before appending: the lines are the Ignore answer, and that
answer is its own approval. If nothing is missing — or the user ignored none of
them — write nothing and say the file was left unchanged.

**If there is no `.gitignore`**, draft it:

1. Detect the project type from the root contents — `package.json` (Node), `pyproject.toml` / `requirements.txt` (Python), `Cargo.toml` (Rust), `go.mod` (Go), `Gemfile` (Ruby), `composer.json` (PHP), Xcode/Android project files, and so on. More than one may apply.
2. Read `${CLAUDE_PLUGIN_ROOT}/skills/docs/gitignore-patterns.md` for the categories worth ignoring — secrets, dependencies, build output, OS/editor cruft, logs and caches, large blobs. If that file cannot be read, fall back to the standard ignore set for the detected stacks.
3. Draft a `.gitignore` covering the categories that actually apply to this project, and check the root contents for anything already sitting there that matches (a stray `.DS_Store`, a `node_modules/`, a `.env`) so it is covered. The editor and tool folders come from Step 2's Ignore answer and from nowhere else — a folder the user chose to track must not appear in the draft, whatever the reference file says about it.

Then follow Step 2's Gitignore answer:

- **Write it** — write the file. Step 5 prints it in full; that is the whole
  point of the option, so the report must not summarise it.
- **Show me the draft first** — print the draft, then use **AskUserQuestion**:
  "Write it / Edit it / Skip .gitignore". Write only after approval.
- **Skip the `.gitignore`** — write nothing.

Complete when a `.gitignore` exists in the root, was appended to, or the user
declined one.

### Step 5 — Report

State the repo root, the base branch, what `origin` points at (or that there is no remote), whether a `.gitignore` was written or appended to, and which tool folders it ignores. Point the user at `commit` for the first commit, suggest the first commit message to be `chore(git): repo init`.

Whatever landed in the `.gitignore` is shown here, because the user may not have
seen it before it was written:

- **Written from a draft the user did not see** — print the complete file.
- **Appended to an existing file** — print the appended lines.
- **Shown before writing, or skipped** — the user has already seen it; a
  one-line summary is enough.

Close with the one command the repo still needs, printed as text to run later and
never run here:

- **A remote was added** — `git push -u origin <base-branch>`, and say it belongs
  *after* the first commit; a branch with no commits has nothing to push.
- **No remote** — `git remote add origin <url>`, for whenever the repository
  exists on the host.

## Integration

- **After this skill**: use `commit` to make the first conventional commit
- **Then**: use `branch` to start feature work off the base branch

## Rules

- Every decision the user has to make goes through **AskUserQuestion** — the nested-repo
  choice, Step 2's batch (branch, remote, tool folders, `.gitignore`), what to do about a
  URL that did not answer, and the drafted file when "Show me the draft first" was picked.
  Never ask in prose and wait for a typed reply
- Ask everything Step 2 can ask in **one** call. A question that only reads the context
  block does not need its own round trip, and none of Step 2's four depends on another
- Never run `git init` outside the project root
- Never guess a remote URL. It is typed by the user into the question's "Other" field or
  it does not exist — never derived from `package.json`, a `gh` config, the directory
  name, or the remote of a parent repo
- Never touch a remote that is already configured. A repo with an `origin` keeps it
  exactly as it is — not re-pointed, not renamed, not offered a replacement
- A URL that does not answer is a warning, never a refusal. A repository not yet created
  on the host, a private one, and a typo look identical from here — the user says which
  it is
- Never overwrite an existing `.gitignore` — append to it or leave it alone
- A `.gitignore` the user never previewed is printed in full in the report. "Write it"
  moves the reading from before the write to after it; it never skips the reading
- Never put `.vscode/`, `.claude/` or the `pm` docs root into a `.gitignore` on your own
  judgement. Those three are commonly committed on purpose, and silently ignoring one
  hides work the user meant to share. Step 2's Ignore answer decides, always
- Never offer to stage or commit anything here. This skill decides what git *ignores*;
  what gets committed is `commit`'s job
- Never push, and never offer to. The report prints `git push -u origin <base-branch>` as
  text for after the first commit exists; running it is the user's move
- `git init` and, when a URL was given, `git remote add origin` are the only writes this
  skill makes to the repo; staging, committing and pushing belong elsewhere

---

# Links

- [gitignore-patterns](../docs/gitignore-patterns.md)
