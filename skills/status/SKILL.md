---
name: status
allowed-tools: Bash(git rev-parse:*), Bash(git log:*), Bash(git status:*), Bash(git branch:*), Bash(bash:*), Bash(wc:*), Read
description: "Show the repository's status as a web page the user can navigate: a dashboard (where HEAD is, recent commits, activity heatmap, worktrees, branch health, tags) and a git tree graph where a commit can be clicked for its message, parents and changed files and branches can be shown or hidden. Use whenever the user wants to see, browse, visualise or navigate the git history or graph, or asks for the repo status in a page. Also triggers for phrases like 'show me the git graph', 'git tree', 'visualize the history', 'browse the commits', 'show the branches', 'open the repo status', 'status page', 'what does the history look like'. Writes the page and its data file to .claude/git-tools/ (status.html and status-data.js) and returns a clickable link."
model: sonnet
---

# Status SKILL

## Context

- Repo check (`(no repo)` means this directory is not under git): !`out=$(git rev-parse --show-toplevel 2>/dev/null) || true; echo "${out:-(no repo)}"`
- Current branch: !`out=$(git branch --show-current 2>/dev/null) || true; echo "${out:-(no branch — detached HEAD, or no repo)}"`
- Git status: !`out=$(git status --short 2>/dev/null) || true; echo "${out:-(working tree clean)}"`
- Commits reachable from any ref: !`out=$(git log --branches --remotes --tags HEAD --format=%H 2>/dev/null | wc -l | tr -d ' ') || true; echo "${out:-0}"`

## Your task

Write an HTML page, with its data file beside it, that shows the whole commit graph of this
repository plus its working-tree status, and give the user a link to it. The page
is a **snapshot**: it is read-only and shows the repository as it was when this
skill ran. Run the skill again to refresh it.

### Step 0 — Confirm there is a repo

If the repo check in the context reads `(no repo)`, this directory is not under
version control. Say so, point the user at `init` to create the repo, and stop.

A repository with no commits yet is fine: the page still opens and says
"No commits yet" next to the working-tree status.

### Step 1 — Generate the page

Run the bundled script as **one** Bash call from anywhere inside the repo. It
makes sure the output folder is ignored by git (adding `.claude/git-tools/` to
`.gitignore` only when nothing already ignores it), gathers the git data and
writes the page and its data file.

```bash
bash "${CLAUDE_PLUGIN_ROOT}/skills/status/scripts/build.sh"
```

It writes `status.html` (a copy of the prebuilt page) and `status-data.js` (the
raw git output the page parses in the browser) side by side, and prints four
lines: `page:` and `data:` (absolute paths), `gitignore entry added:` (`yes` or
`no`) and `commits:` (the count). The two files must stay together. Do not
hand-edit them or trim the history — the page is meant to carry the full
history. See [build.sh](scripts/build.sh).

### Step 2 — Hand over the link

Reply in a few lines:

1. The page as a clickable `file://` link whose text is `status.html`, with the
   bare `file://…` URL right after it so it can be copied into a browser.
2. The commit count, and whether a `.claude/git-tools/` line was added to
   `.gitignore` (that edit is a change the user may want to commit).
3. One line on what the page does: a dashboard with the current branch, recent
   commits, activity, worktrees, branch health and tags, plus a graph page
   where a commit opens its details and branches can be shown or hidden. It
   has a light/dark theme and English and Brazilian Portuguese, both
   remembered by the browser.
4. One line of caveat: it is a snapshot (run `status` again to refresh). The
   page and its data file are static, so it works offline from disk; keep the
   two files together if you move them.

Do not try to open the page yourself: `open` and `osascript` are blocked in
sandboxed sessions. If the user asks you to open it, give them
`open <path>` (macOS) or `xdg-open <path>` (Linux) to run.

### Rules

- Read-only on the repository: this skill never commits, stages, fetches,
  switches branches or changes history. Its only writes are the generated page
  and, when needed, one line in `.gitignore`.
- The remote-tracking refs shown are as of the last fetch. Say so if the user
  asks why a remote branch looks stale; do not fetch on their behalf.
- Never put secrets or anything outside the repo's own git data in the page.
