---
name: init
allowed-tools: Bash(git init:*), Bash(git rev-parse:*), Bash(git status:*), Bash(git branch:*), Bash(git config:*), Bash(git check-ignore:*), Bash(ls:*), Bash(cat:*), Bash(head:*), Bash(find:*), Bash(grep:*), Bash(date:*), Bash(echo:*), Bash(rm:*), Bash(sed:*), Read, Write, Edit, Skill
description: Put the project root under git locally — the base branch, then one question each for the three starter files, .gitignore, README.md and LICENSE, whether they are already there or not. Use when the user wants a project under version control, asks whether it is a repo yet, or says things like 'set up git here', 'write a starter README', 'replace my gitignore'. Also covers naming the base branch of a brand-new repo. Local only — no remote is created or configured.
disable-model-invocation: true
model: sonnet
---

# Init SKILL

## Context

- Project root: !`out=$(pwd 2>/dev/null) || true; echo "${out:-(working directory is gone)}"`
- Repo toplevel (`(no repo)` means this directory is not in a git repo): !`out=$(git rev-parse --show-toplevel 2>/dev/null) || true; echo "${out:-(no repo)}"`
- Configured default branch: !`out=$(git config --get init.defaultBranch 2>/dev/null) || true; echo "${out:-(unset)}"`
- Root contents: !`out=$(ls -A 2>/dev/null) || true; echo "${out:-(empty directory)}"`
- Editor and tool folders present (`(none)` means there is nothing to decide): !`out=$(ls -d .vscode .idea .zed .fleet .claude 2>/dev/null) || true; echo "${out:-(none)}"`
- Docs root managed by `pm`: !`out=$(find . -mindepth 2 -maxdepth 2 -name pm.config.json 2>/dev/null | sed 's|/pm.config.json$||; s|^\./||') || true; echo "${out:-(none)}"`
- Existing .gitignore: !`out=$(head -40 .gitignore 2>/dev/null) || true; echo "${out:-(none)}"`
- Existing README / LICENSE: !`out=$(ls -A 2>/dev/null | grep -iE "^(readme|license|licence|copying)") || true; echo "${out:-(none)}"`
- Name for the copyright line: !`out=$(git config --get user.name 2>/dev/null) || true; echo "${out:-(unset)}"`
- Current year: !`out=$(date +%Y 2>/dev/null) || true; echo "${out:-(unknown)}"`


## Your task

Put the project root under git **locally**, and settle the three starter files — `.gitignore`, `README.md`, `LICENSE` — whether they are missing or already there.

The skill ends at the local repository. A repo with no remote is a finished repo, and the report says so as a fact about what was done rather than as work left over.

### Step 1 — Establish repo state

Read the context above and settle on exactly one of three states.

| State | Signal | What to do |
|---|---|---|
| **Already a repo** | Repo toplevel equals the project root | Report the current branch and status, then stop — there is nothing to initialize |
| **Inside a parent repo** | Repo toplevel is an *ancestor* of the project root | Report the parent repo's path, then use **AskUserQuestion**: work in the parent repo, or create a nested repo here (warn that nesting confuses tooling and the parent will see this directory as untracked) |
| **No repo** | Repo toplevel reads `(no repo)` | Continue to Step 2 |

Complete when the state is named out loud and, for the first two, the user has been told what it means.

### Step 2 — The branch, and each of the three starter files

**One AskUserQuestion** call, always four questions: the branch, then `.gitignore`, `README.md` and `LICENSE`, one question each. Every file gets one whether or not it is there — what changes is which options it carries.

**The branch question** lists `master` first and as the default, then `main`, then the *Configured default branch* from the context when it is set and is neither of those. The tool's built-in "Other" choice takes any other name — ask for one there rather than in prose.

**A file the context found** — `.gitignore`, a `README*`, a `LICENSE*` or a `COPYING*`:

| # | Option | What it does |
|---|---|---|
| 1 | **Leave it as it is** | Nothing is written. The default |
| 2 | Amend it — add what the template has and it lacks | Adds to the file and rewrites none of it |
| 3 | Delete and recreate it from the template | Discards the current content and writes the template |
| 4 | Delete it | Removes the file, writes nothing |

Options 3 and 4 discard what is there. Say so in the question's text, and say that **nothing is committed yet**, so git has no copy to recover it from.

For a `LICENSE` there is no template to read those rows against: row 2 amends the copyright line and leaves the licence text on disk exactly as it is, and row 3 writes the licence chosen in Step 4.

**A `.gitignore` or a `README.md` the context did not find:**

| # | Option | What it does | Offered when |
|---|---|---|---|
| 1 | **Create it from the template, adapted to this project** | The template, with what the project's own files answer filled in | there is a project here — see below |
| 2 | Create it from the template | The template as it is, placeholders and all | always |
| 3 | Skip it | Nothing is written | always |

Option 1 is the default where it is offered, option 2 where it is not.

**A `LICENSE` the context did not find** gets two options and never three: write one, or skip it. There is no adapted option, because a licence text adapts to nothing — *which* licence is the only open question, and it is asked in Step 4 and answered by [`licensing`](../licensing/SKILL.md).

**"Adapted to this project" needs a project to adapt to.** Withhold option 1 in exactly one case: the context block's `ls -A` shows nothing but `.git/`, `.gitattributes` and the starter files this skill itself writes — `.gitignore`, `README*`, `LICENSE*`, `COPYING*`. There is then nothing to read but git's own bookkeeping and this skill's own output, so the option would produce exactly what option 2 produces while implying otherwise. Anything else in the root — a manifest, a source directory, a `Makefile`, an editor or tool folder, a stray file — is something to read, and the option is offered.

Leaving every existing file alone and skipping every missing one is a complete answer. The repo still gets initialized; Steps 4 and 5 then have nothing to do.

Complete when a branch name is settled and each of the three files has an outcome — left alone, amended, recreated, deleted, created or skipped.

### Step 3 — Initialize

1. Run `git init -b <base-branch>`.
2. If that fails because the git version predates `-b`, run `git init`, then `git branch -m <base-branch>`.
3. Confirm the name with `git branch --show-current`.

Use `git branch --show-current` and not `git rev-parse --abbrev-ref HEAD`. A just-initialized repo has an **unborn HEAD** — the ref names the branch but no commit has been made on it — so `rev-parse` exits `128` with `ambiguous argument 'HEAD'` in the one state this step is always in, while `--show-current` reads the ref itself and exits `0`.

Complete when HEAD is on the chosen branch.

### Step 4 — Survey the project, then ask what the templates cannot answer

Step 2 settled what happens to each file and where its content comes from. What remains is the reading that "adapted" promised, and the questions no template and no file on disk can answer.

#### The survey

It runs **here** — after `git init`, before the questions below are drafted — and **only when at least one file's Step 2 answer was *adapted***. If none was, go straight to the questions.

Walk the tree from the project root under two bounds, and no others:

- **Depth 4.** `find . -maxdepth 4`. Deeper than `apps/web/src/`, shallow enough that no tree can stall the skill.
- **No dependency or build directories.** Never descend into `node_modules`, `vendor`, `.venv`, `venv`, `target`, `build`, `dist`, `out`, `.next`, `Pods` or `.git`. A vendored copy of someone else's project is not this project, and its manifests would report stacks this repo does not use.

Collect three things, and nothing else:

| For                               | What to collect                                                                                                                                                                                                                                                                                                        |
| --------------------------------- | ---------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------- |
| The `.gitignore`                  | Every stack a manifest indicates **anywhere in the walk**, not only in the root: `package.json` (Node), `pyproject.toml` / `requirements.txt` (Python), `Cargo.toml` (Rust), `go.mod` (Go), `Gemfile` (Ruby), `composer.json` (PHP), Xcode/Android project files. More than one may apply, and a monorepo usually does |
| The `README.md` name and commands | The name from a root manifest, else the directory name. Every command that **literally exists**: `package.json` scripts, `Makefile` targets, `justfile` recipes, `pyproject.toml` `[project.scripts]`, Cargo bins, task-runner entries                                                                                 |
| The `README.md` description       | A manifest's `description` field, verbatim. If no manifest carries one, read enough of the tree to draft **2–3 lines** saying what the project is — and take that draft to the Description question below rather than writing it                                                                                       |

#### The questions

Up to three, in **one AskUserQuestion** call. Include only the ones that apply;
if none does, skip them.

| Header | Question | Options | Included when |
|---|---|---|---|
| Ignore | Which of these should git ignore? (`multiSelect: true`) | one per folder the context actually found — see below | a `.gitignore` is being created, amended or recreated, *and* the editor and tool folders or docs root line found something |
| License | Which licence? | **MIT** / Apache-2.0 / GPL-3.0 / Show me all of them | a `LICENSE` is being created or recreated |
| Description | This is what the project's files say it is — use it? | **the drafted 2–3 lines** / Leave the placeholder, I will write it myself | the `README.md` is being adapted *and* no manifest carried a `description` |

Bolded options are the defaults — list them first.

**The Ignore options.** Whether `.vscode/` belongs to the team or to the person is a decision, not a fact about the stack — the one part of a `.gitignore` the project type cannot answer. One option per folder the context found, and **never list a folder that is not there**:

| Folder | Recommendation | Why |
|---|---|---|
| `.vscode/` | Track | Workspace settings — fonts, the window colour, task definitions — are the same for everyone working on the project |
| The `pm` docs root (`.pm/`, `.docs/`, …) | Track | PRDs, specs and decision logs are the project's writing; ignoring them means only the author ever reads them |
| `.claude/` | Track | Project skills, agents and hooks are shared setup; only `settings.local.json` inside it is personal |
| `.idea/`, `.zed/`, `.fleet/` | Ignore | Mostly per-user IDE state — window layout, caches, local run configs |

Mark the recommended choices in the option labels, and say in the question that this only decides what the `.gitignore` says: ignoring a folder does not un-track it once it has been committed.

**The License question** offers the three licences [choosealicense.com](https://choosealicense.com/licenses/) features — MIT, Apache-2.0, GPL-3.0 — plus *Show me all of them*, which hands the choice to [`licensing`](../licensing/SKILL.md) and its catalogue of forty-seven. The tool's "Other" box takes a name or an SPDX id directly: `BSD-3-Clause`, `MPL-2.0`, `AGPL-3.0`, `Unlicense`, `ISC`. Give each listed option a one-line gloss of what it grants, so the choice is made on terms rather than on familiarity:

| Option | Gloss |
|---|---|
| **MIT** | Short and permissive. Do anything, keep the notice |
| Apache-2.0 | Permissive, with an explicit patent grant and a changes notice |
| GPL-3.0 | Copyleft. Anything distributed that builds on it ships its source under the same terms |

Read the licence from the answer and from nowhere else — not from the stack's convention, not from a manifest's `license` field, not from a sibling project. A licence is the one thing in a repository that is a legal decision rather than a technical one, and the wrong guess is one the user has to undo with every contributor's agreement.

**The Description question** is the one place this skill composes a sentence the project never wrote. Put the draft in the option's label, in full — the user is approving the actual line, not the idea of one. The "Other" box carries a rewrite in their own words, and leaving the placeholder is a finished answer, not a deferral. Skip the question entirely when a manifest already carries a `description` — those are the project's own words, and they go in unasked.

Complete when every included question has an answer.

### Step 5 — Carry out each file's decision

Two files come from a template the plugin ships; the third comes from another skill:

| File | Where its content comes from |
|---|---|
| `.gitignore` | `${CLAUDE_PLUGIN_ROOT}/skills/init/templates/gitignore.template` |
| `README.md` | `${CLAUDE_PLUGIN_ROOT}/skills/init/templates/README.template.md` |
| `LICENSE` | [`licensing`](../licensing/SKILL.md), which ships the catalogue and writes the file |

The two templates are written as they ship. **Nothing is invented, on any path** — no feature list, no badges, no roadmap, no author. A placeholder in angle brackets is filled in only where something already on disk answers it, or where the user approved a line in Step 4, and left standing where neither does: a stub the user completes beats a plausible line that is wrong.

**Delete, and the delete half of "delete and recreate"** — remove exactly the file the user named, with `rm <path>` and no flags: no `-r`, no `-f`, and no second path on the line.

**Recreate** — after the delete, write the file exactly as the plain-template path below writes it. Recreating is not adapting: it takes the template, not the project.

#### `.gitignore`

The stacks come from Step 4's survey, which looked at the whole bounded tree and not only at the root — a monorepo whose root holds no manifest at all still has stacks to cover. Whichever path runs, the editor and tool folders come from Step 4's Ignore answer and from nowhere else: a folder the user chose to track stays out of the file, whatever the template or the reference says about it.

- **Amend** — do not redraft it. Append the template entries the file does not already cover, checking each with `git check-ignore -q <pattern>` — which answers by exit status: `0` means the pattern is already covered, `1` means it is not and should be appended. A `1` here is the answer, not a failure. Then append the Step 4 folders that are not covered either, and leave the rest of the file alone. If nothing is missing, write nothing and say the file was left unchanged.
- **From the template** — write the template as it is, then append the Step 4 folders it does not cover.
- **From the template, adapted** — start from the template, then read `${CLAUDE_PLUGIN_ROOT}/skills/commit/references/gitignore-patterns.md` and add what every stack the survey found needs, under the categories it names: secrets, dependencies, build output, OS and editor cruft, logs and caches, large blobs.
  Add anything already sitting on disk that should be covered (a stray `.DS_Store`, a `node_modules/`, a `.env`). Then append the Step 4 folders.

  Write patterns that match at any depth — `node_modules/`, not `apps/web/node_modules/` — unless the pattern is inherently rooted. One unanchored line covers every copy the survey found, and the file stays readable as the tree grows.

#### `README.md`

- **Amend** — append only the template sections the file does not have, in the template's order, each as a placeholder stub. Do not touch a heading, a sentence or a code block that is already there.
- **From the template** — write it as it is, placeholders and all, except that the title takes the project name when the directory name or a manifest gives one.
- **From the template, adapted** — fill in three things and leave every other placeholder standing.

On both paths the `## License` section takes the name of the licence Step 4 chose, and is dropped entirely when no licence file will exist.

| Placeholder                  | What fills it                                                                                                                                                                                                                                                           |
| ---------------------------- | ----------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------- |
| `# <project name>`           | A root manifest's `name`; failing that, the directory name                                                                                                                                                                                                              |
| `<One line: …>`              | A manifest's `description`, verbatim and unedited. If none, the 2–3 lines the user approved in Step 4 — and if they declined, the placeholder stays                                                                                                                     |
| The Install and Usage blocks | **Only a command that literally exists** as a script, target, recipe or entry point in something the survey read. `npm install` is an inference from a `package.json`, not a fact the project stated, and does not go in. A block nothing answers keeps its placeholder |

#### `LICENSE`

The licence text comes from [`licensing`](../licensing/SKILL.md), byte for byte. This skill settles *whether* and *which*, and hands over. A licence is a legal instrument whose force is in its exact words, and two hundred lines of Apache written from memory is a plausible forgery rather than a licence.

**Amend** hands nothing over: leave the licence text on disk exactly as it is, and fill the copyright line only when it is missing or still a placeholder, from the *Name for the copyright line* and *Current year* lines of the context block. The README's `## License` line needs this licence's name — take it from `head -3` of the file the context block found, the title block every licence carries (`MIT License`; `Apache License` / `Version 2.0`; `GNU GENERAL PUBLIC LICENSE` / `Version 3`). Three lines names it, and the rest of the file stays shut.

**Create** and **recreate** hand over once, before the `README.md` is written:

> Invoke `git-tools:licensing` with `args: "copy <the answer to the License question>"` — `args: "copy MIT"`, or `args: "copy"` alone when the answer was *Show me all of them*. Pass the answer verbatim, including anything typed into "Other". Pass no name and no year: `licensing` reads `user.name` itself and asks when it is unset.

When it finishes, two things are settled: the licence's **full name** and the **path** it wrote. Use the name `licensing` resolved rather than the words typed into the question — text typed into "Other" may have matched a different licence. Read the file's name and leave its contents alone on this path: opening a `LICENSE` is how licence text gets into the conversation, and from there into a `Write` call.

Two outcomes, neither a failure:

- **A file was written.** Its licence name fills the README's `## License` line and the Step 6 report; its path is the file's path for the rest of this skill.
- **Nothing was written** — the user backed out, or nothing matched what they typed. Report the `LICENSE` as not written, drop the README's `## License` section the way a skipped licence drops it, and carry on with the rest of Step 5. A half-written `LICENSE` claims terms the project does not have.

Complete when every file's decision has been carried out — or the user was told, per file, exactly why it was not.

### Step 6 — Report

Name the repo root, the base branch, that the repo is local with no remote, and each of the three starter files with its path and what happened to it. Then point the user at `commit` for the first commit, suggesting `chore(git): repo init` as its message.

**Name the path and the outcome, and stop there.** Every file named here is on disk at a path the user can open, and a report that reprints what it just wrote — in full, as an excerpt, as the added lines or as licence text — buries the one thing only the report can say: what happened, and what is left to do.

- **Created or recreated** — say which source it came from: the template as it ships, the template with the Step 4 answers filled in, or, for the `LICENSE`, the licence by name and that `licensing` wrote its text verbatim from the catalogue the plugin ships.
- **Amended** — say how many lines were added and what they cover (for example, "3 lines, the editor folders you chose"). Describe them; do not reproduce them.
- **Deleted** — say so plainly, and that it is not recoverable from git.
- **Adapted** — name which placeholders the survey filled and which are still standing, by the section they sit in rather than by quoting them, so the remaining ones read as work left rather than as an oversight. If the README's description is the drafted one, say it was written here and approved, not lifted from the project.

## Rules

- Any git command you run during the task must be written so a non-zero exit cannot abort the step. Use `out=$(<command> 2>/dev/null) || true; echo "${out:-(marker)}"`, the same form the context block uses. Several git commands report an ordinary, expected answer through a non-zero status — `check-ignore` exits `1` for "not ignored", `config --get` exits `1` for "unset", `config --unset` exits `5` for "was not set", `rev-parse HEAD` exits `128` on a repo with no commits — and an unguarded one of those reads as a crash and stops work that should have continued
- Do not re-run a context command just to confirm what is already printed above. Do re-check when its output contradicts itself or carries a shell error — a wrong answer is worth verifying — but re-run it in the guarded form, never bare, or the check fails the same way the original did
- Never put an unquoted glob (`README*`, `*.md`) in a command. Shells disagree about an unmatched one: bash and `sh` pass it through literally, zsh aborts the whole command before it runs and prints `no matches found` — which no `2>/dev/null` can suppress, because the shell emits it during expansion rather than the command emitting it. The result is a confident wrong answer. List the directory and filter it instead: `ls -A | grep -iE "^(readme|license)"`

## Integration

- **During this skill**: [`licensing`](../licensing/SKILL.md), invoked in Step 5 whenever a `LICENSE` is being created or recreated
- **After this skill**: [`commit`](../commit/SKILL.md), for the first conventional commit

---

# Links

- [gitignore-patterns](../commit/references/gitignore-patterns.md)
- [templates](templates/)
- [licensing](../licensing/SKILL.md)
- [commit](../commit/SKILL.md)
