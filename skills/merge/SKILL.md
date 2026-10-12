---
name: merge
allowed-tools: Bash(git branch:*), Bash(git switch:*), Bash(git merge:*), Bash(git merge-base:*), Bash(git rebase:*), Bash(git stash:*), Bash(git status:*), Bash(git log:*), Bash(git diff:*), Bash(git rev-parse:*), Bash(git rev-list:*), Bash(git remote:*), Bash(git fetch:*), Bash(git push:*), Bash(git add:*), Bash(git commit:*), Bash(git reset:*), Bash(ls:*), Bash(grep:*), Bash(echo:*), Read, Edit
description: "Merge one git branch into another after confirming the merge type, the origin branch and the target branch, and after settling any uncommitted changes by committing or stashing them. Use whenever the user wants to merge a branch, finish a branch, bring a feature into master or main, squash a branch, fast-forward, or rebase and merge. Also triggers for phrases like 'merge this', 'merge feat/x into master', 'merge my branch', 'land this branch', 'squash and merge', 'I'm done with this branch', 'bring this into main'. Offers a merge commit (--no-ff), fast-forward only, squash, or rebase then fast-forward, and handles conflicts and branch cleanup."
model: sonnet
---

# Merge SKILL

## Context

- Repo check (`(no repo)` means this directory is not under git): !`out=$(git rev-parse --show-toplevel 2>/dev/null) || true; echo "${out:-(no repo)}"`
- Current branch: !`out=$(git branch --show-current 2>/dev/null) || true; echo "${out:-(no branch — detached HEAD, or no repo)}"`
- Local branches: !`out=$(git branch --list 2>/dev/null) || true; echo "${out:-(no branches yet)}"`
- Remote-tracking branches (as of the last fetch): !`out=$(git branch -r 2>/dev/null) || true; echo "${out:-(no remote-tracking branches)}"`
- Remotes: !`out=$(git remote 2>/dev/null) || true; echo "${out:-(no remotes)}"`
- Current branch and its upstream: !`out=$(git status -sb 2>/dev/null | head -1) || true; echo "${out:-(no repo)}"`
- Git status: !`out=$(git status --short 2>/dev/null) || true; echo "${out:-(working tree clean)}"`
- Stashes: !`out=$(git stash list 2>/dev/null) || true; echo "${out:-(no stashes)}"`
- Merge in progress: !`out=$(git rev-parse -q --verify MERGE_HEAD 2>/dev/null) || true; echo "${out:-(no merge in progress)}"`
- Rebase in progress: !`out=$(ls -A "$(git rev-parse --git-dir 2>/dev/null)" 2>/dev/null | grep -E "^rebase-(merge|apply)$") || true; echo "${out:-(no rebase in progress)}"`

## Your task

Merge an **origin** branch into a **target** branch, with the merge type, both
branches, the remote handling and the fate of any uncommitted work all decided
by the user before anything moves.

Remember the branch the user is on now — the **starting branch**. The skill ends
there, unless that branch is deleted in Step 8, in which case it ends on the
target.

### Step 0 — Confirm there is a repo

If the repo check in the context reads `(no repo)`, this directory is not under
version control. Say so, point the user at `init` to create the repo, and stop —
nothing below applies until there is one.

If the current branch reads as a detached HEAD, say so and stop: there is no
branch to merge from or into until the user switches to one.

### Step 1 — Clear an unfinished merge or rebase

If the context shows a merge or a rebase in progress, a previous one was left
half-done and a new merge cannot start on top of it. List the conflicted files,
if any (`git diff --name-only --diff-filter=U`), and use **AskUserQuestion**:

- **Abort it** — `git merge --abort` or `git rebase --abort`, back to where it
  started, then carry on with this merge
- **Finish it first** — go to Step 7 and resolve it as if it had just stopped
  there; start this merge only once it has landed
- **Cancel** — touch nothing and stop

### Step 2 — Remotes

If the context shows no remotes, everything is local: skip this step and say so
in the report.

Otherwise use **AskUserQuestion** — the user decides how this merge treats the
remote every time; it is never assumed:

| Option | What happens |
|---|---|
| **Local only (Recommended)** | No fetch, no push. Branches are offered as they are on disk; the remote-tracking branches in the context are as old as the last fetch. |
| Fetch first, never push | `git fetch --prune` before the branches are listed, so the target is checked against its real upstream and a remote branch can be the origin. Pushing stays the user's job. |
| Fetch first, offer push | As above, and Step 8 asks whether to push the target once the merge lands. |

After a fetch, re-read the branch lists in the guarded form — the context block
is from before it.

### Step 3 — Propose origin and target

1. **Origin** — the branch the user named; otherwise the current branch. After a
   fetch, a remote-tracking branch (`origin/feat/x`) may be the origin too, but
   only a local branch can be rebased or deleted.
2. **Target** — the branch the user named; otherwise the base branch: `master` or
   `main`, whichever exists locally. If both or neither exist, the target is a
   question with no default.
3. If origin and target are the same branch, say so and ask again — a branch
   cannot be merged into itself.
4. Measure the pair:

   ```bash
   out=$(git rev-list --left-right --count <target>...<origin> 2>/dev/null) || true; echo "${out:-(cannot compare)}"
   out=$(git log --oneline <target>..<origin> 2>/dev/null) || true; echo "${out:-(nothing to merge)}"
   ```

   The first prints `<target-only> <origin-only>`. If the origin has no commits
   the target lacks, the origin is already merged: report that and stop.
5. If remotes are in play and the target is behind its own upstream, the merge
   would land on a stale target. Use **AskUserQuestion**: "Fast-forward the
   target to its upstream first (Recommended) / Merge into it as it is / Cancel".
   The fast-forward is `git merge --ff-only @{u}` with the target checked out, in
   Step 6, before the merge itself.

### Step 4 — Confirm merge type, origin and target

Print the commits that will land (from Step 3) and the ahead/behind counts. Then
use a **single AskUserQuestion** call carrying three questions:

| Header | Question | Options |
|---|---|---|
| Origin | Merge from which branch? | the proposed origin first, then up to three other likely branches; any other through "Other" |
| Target | Into which branch? | the proposed target first, then the other base branch if one exists; any other through "Other" |
| Merge type | How should it land? | see below |

Merge type options, in this order — **merge commit is always the recommendation**:

1. **Merge commit (`--no-ff`) (Recommended)** — always records a merge commit,
   so the branch's history and the point it joined stay visible
2. **Fast-forward only** — moves the target with no new commit; linear, nothing
   rewritten. Only possible when the target has no commits of its own since the
   branches split (`<target-only>` is `0`): when it does, say in this option's
   description that git will refuse it
3. **Squash** — the whole branch lands as one new commit on the target, with a
   message drafted in Step 6. The origin's own commits stay on the origin only
4. **Rebase then fast-forward** — replays the origin's commits on top of the
   target, then fast-forwards; linear with every commit kept, but it rewrites
   the origin's commits. When the origin has an upstream, say so in the
   description: anyone who pulled it will have to reconcile. Not offered when
   the origin is a remote-tracking branch

If the user changes origin or target through "Other", re-run Step 3 for the new
pair and re-ask. Nothing moves until this step returns approval.

### Step 5 — Settle uncommitted changes

If the context's git status reads `(working tree clean)`, skip this step.

Otherwise the work in progress belongs to the starting branch and must not ride
along into the merge. List the files and use **AskUserQuestion**:

- **Commit first (Recommended)** — hand off to `commit`, and resume here once it
  has landed. The changes are kept in history on the starting branch
- **Stash, then restore (Recommended)** — stash now, restore when the merge is
  done (Step 9)
- **Stash and leave it** — stash now and leave it stashed; the report names the
  stash entry so the user restores it when they want
- **Cancel (Recommended)** — touch nothing and stop, so the user deals with the
  changes themselves

The stash takes untracked files too and is labelled so it can be found again:

```bash
git stash push -u -m "merge: <origin> into <target>"
```

After a commit or a stash, check the tree is clean (`git status --short`) before
moving on. A merge never starts on a dirty tree.

### Step 6 — Merge

For a squash, draft the commit message **before** running anything: one
conventional message summing up `git log <target>..<origin>`, following
`${CLAUDE_PLUGIN_ROOT}/skills/commit/references/conventional-commits-1.0.0.md`,
and confirm it with **AskUserQuestion** — the full message as visible question
text, options "Send it! / Edit message / Abort".

Then, by merge type:

| Type | Commands |
|---|---|
| Merge commit | `git switch <target>` · `git merge --no-ff --no-edit <origin>` |
| Fast-forward only | `git switch <target>` · `git merge --ff-only <origin>` |
| Squash | `git switch <target>` · `git merge --squash <origin>` · `git commit` with the approved message, through a HEREDOC |
| Rebase then fast-forward | `git switch <origin>` · `git rebase <target>` · `git switch <target>` · `git merge --ff-only <origin>` |

The merge commit keeps git's own message — `Merge branch '<origin>' into
<target>` — and is never reworded. If Step 3 settled on fast-forwarding the
target to its upstream, run `git merge --ff-only @{u}` right after switching to
the target, before the merge.

If a fast-forward is refused because the branches have diverged, nothing has
changed: say so and offer the other merge types through **AskUserQuestion**.

If git stops on conflicts, go to Step 7. Otherwise go to Step 8.

### Step 7 — Conflicts

List the conflicted files (`git diff --name-only --diff-filter=U`) and use
**AskUserQuestion**:

- **Resolve them together (Recommended)** — for each file, read both sides of
  every conflict, propose a resolution, show it, and write it only once the user
  approves it through **AskUserQuestion**; then `git add <file>`. When every file
  is staged, continue the operation: `git commit --no-edit` for a merge commit,
  `git commit` with the approved message for a squash, `git rebase --continue`
  for a rebase — which may stop again on a later commit; repeat this step until
  it finishes, then run the fast-forward from Step 6
- **Abort** — put everything back as it was before Step 6: `git merge --abort`
  for a merge commit, `git reset --merge` for a squash (it leaves no `MERGE_HEAD`
  to abort from), `git rebase --abort` for a rebase. Then go to Step 9 and report
  the merge as not done

Never resolve a conflict by taking one side wholesale (`-X ours`, `-X theirs`,
`checkout --ours`) without the user picking that for the file.

### Step 8 — Push and clean up

**Push** — only when the user chose "Fetch first, offer push" in Step 2. Use
**AskUserQuestion**: "No, keep it local (Recommended) / Push `<target>`". A push
is `git push <remote> <target>`; never `--force`.

**Delete the origin** — only when the origin is a local branch. Use
**AskUserQuestion**: "Keep `<origin>` (Recommended) / Delete it". The delete is
`git branch -d <origin>`, which refuses a branch whose commits are not all on
the target. After a squash it always refuses — the squash made new commits, not
the origin's — so offer `git branch -D <origin>` instead and say why in the
option's description. Never `-D` on any other path.

**Delete the remote branch** — only when remotes are in play and the origin has
an upstream. Its own **AskUserQuestion**, asked separately from the local one:
"Keep `<remote>/<origin>` (Recommended) / Delete it from `<remote>`". The delete
is `git push <remote> --delete <origin>`. When the origin itself was a
remote-tracking branch, this is the only delete offered.

### Step 9 — Return and restore

1. Switch back to the starting branch, unless it was deleted in Step 8 — then
   stay on the target, and say so.
2. If the user chose "Stash, then restore", `git stash pop`. If the pop
   conflicts, git keeps the stash: leave it in place, list the conflicted files
   and say the stash entry is still there. Never `git stash drop` it.
3. If the user chose "Stash and leave it", name the stash entry
   (`git stash list`) so it can be found again.

### Step 10 — Report

State plainly:

- Origin → target, and the merge type
- What landed: the merge or squash commit SHA and subject, or the new tip after a
  fast-forward, and how many commits
- Conflicts, and how each file was resolved — or that the merge was aborted
- Remote handling: local only, fetched, pushed or not (with the push command when
  not)
- Branches deleted, local and remote
- Where the user is now, and where the uncommitted changes went: committed,
  restored, or still stashed (with the entry name)

If any step was skipped or failed, say which and why. Never report a merge as
done when the commit did not land.

## Integration

- **Before this skill**: `branch` to start the work, `commit` to record it ([branch](../branch/SKILL.md), [commit](../commit/SKILL.md))
- **During this skill**: `commit` when there are uncommitted changes to keep ([commit](../commit/SKILL.md))
- **After this skill**: `changelog` to log the work under `## [Unreleased]`, `release` when the target is ready to ship ([changelog](../changelog/SKILL.md), [release](../release/SKILL.md))

## Rules

- Every decision the user has to make goes through **AskUserQuestion** — an
  unfinished merge, the remote handling, origin, target, merge type, uncommitted
  changes, the squash message, each conflict, the push, each delete. Never ask in
  prose and wait for a typed reply
- Nothing moves until Step 4 returns approval, and a merge never starts on a
  dirty tree
- Merge commit (`--no-ff`) is always the recommended merge type
- Never force anything: no `push --force`, no `reset --hard`, no `branch -D`
  outside the squash case, no `stash drop`
- Never merge into or from a detached HEAD
- Never push without the user choosing it in Step 8, and only when they picked
  "Fetch first, offer push" in Step 2
- This skill keeps no reference of its own: `conventional-commits-1.0.0.md`
  belongs to `commit`, and it reads it across for the squash message. If it
  cannot be read, look for it in the `references/` folder beside that skill's
  `SKILL.md`. Never draft a squash message from memory because it did not load —
  say what failed and stop
- NEVER include co-authoring or attribution references in commits
- Any git command you run during the task must be written so a non-zero exit
  cannot abort the step. Use `out=$(<command> 2>/dev/null) || true; echo "${out:-(marker)}"`,
  the same form the context block uses. Several git commands report an ordinary,
  expected answer through a non-zero status — `check-ignore` exits `1` for "not
  ignored", `config --get` exits `1` for "unset", `config --unset` exits `5` for
  "was not set", `rev-parse HEAD` exits `128` on a repo with no commits, `merge`
  exits `1` when it stops on conflicts — and an unguarded one of those reads as a
  crash and stops work that should have continued
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

- [conventional-commits-1.0.0](../commit/references/conventional-commits-1.0.0.md)
- [commit](../commit/SKILL.md)
- [branch](../branch/SKILL.md)
