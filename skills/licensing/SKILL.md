---
name: licensing
allowed-tools: Bash(git rev-parse:*), Bash(pwd:*), Bash(git config:*), Bash(ls:*), Bash(find:*), Bash(xargs:*), Bash(awk:*), Bash(grep:*), Bash(sed:*), Bash(head:*), Bash(sort:*), Bash(wc:*), Bash(cut:*), Bash(rm:*), Bash(mv:*), Bash(date:*), Bash(echo:*)
description: Explain, compare and write open-source licences from the plugin's own copy of the choosealicense.com catalogue — what a licence permits, requires and limits, where two of them differ, and the verbatim text that lands in a project's LICENSE file. Use when the user asks which licence to pick, what one of them costs, how two differ, or says things like 'help me choose a licence', 'which licence fits this project', 'add a licence to this project', 'list the licences', 'what does copyleft actually require', 'I want something permissive', 'is MIT or Apache better here'.
model: sonnet
---

# Licensing SKILL

## Context

- Where a `LICENSE` goes — the repo toplevel, else this directory: !`out=$(git rev-parse --show-toplevel 2>/dev/null || pwd) || true; echo "${out:-(unknown)}"`
- Licence file already there: !`out=$(ls -A "$(git rev-parse --show-toplevel 2>/dev/null || pwd)" 2>/dev/null | grep -iE "^(license|licence|copying|unlicense)") || true; echo "${out:-(none)}"`
- Licence a manifest already declares: !`d=$(git rev-parse --show-toplevel 2>/dev/null || pwd); out=$(grep -iE '"?licen[cs]e"?[[:space:]]*[:=]' "$d/package.json" "$d/Cargo.toml" "$d/pyproject.toml" "$d/composer.json" 2>/dev/null | sed "s|^$d/||" | head -4) || true; echo "${out:-(none)}"`
- Name for the copyright line: !`out=$(git config --get user.name 2>/dev/null) || true; echo "${out:-(unset)}"`
- Address, for the licences that ask for one: !`out=$(git config --get user.email 2>/dev/null) || true; echo "${out:-(unset)}"`
- Current year: !`out=$(date +%Y 2>/dev/null) || true; echo "${out:-(unknown)}"`

## Your task

Answer for a licence out of the catalogue this plugin ships, in one of four ways: **choose** one by answering for what the project needs, **copy** it into the project, **learn** what it says, or **compare** it with another.

The catalogue is a vendored snapshot of `choosealicense.com`: one `<slug>.txt` per licence, each YAML frontmatter between `---` fences followed by the licence text, plus `rules.yml`, which defines every tag those frontmatters use, and `SOURCE.md`, which dates the snapshot.

Each Bash call is a fresh shell, so `refs` is set on the same line, every time:

```
refs="${CLAUDE_PLUGIN_ROOT}/skills/licensing/references"
```

Nine commands serve every step, and each of them answers its question outright — the counting, the classifying, the joining of a tag to its meaning and the filling in of a placeholder all happen in `scripts/`, so the same request gives the same answer twice running. Each appears once, here.

**The index** — one line per licence, `slug — Title (SPDX-Id)  [nickname]`, starred where choosealicense features it:

```bash
refs="${CLAUDE_PLUGIN_ROOT}/skills/licensing/references"; out=$(find "$refs" -maxdepth 1 -name '*.txt' 2>/dev/null | sort | xargs awk -f "$refs/../scripts/index.awk" 2>/dev/null) || true; echo "${out:-(no references)}"
```

**Candidates for a name** — the words the user typed go in `Q`, and the last line is the verdict:

```bash
refs="${CLAUDE_PLUGIN_ROOT}/skills/licensing/references"; out=$(Q="<the words>" awk -f "$refs/../scripts/resolve.awk" "$refs"/*.txt 2>/dev/null) || true; echo "${out:-(no references)}"
```

**Every licence's shape** — its class, its slug, then the `conditions` it charges:

```bash
refs="${CLAUDE_PLUGIN_ROOT}/skills/licensing/references"; out=$(find "$refs" -maxdepth 1 -name '*.txt' 2>/dev/null | sort | xargs awk -f "$refs/../scripts/shape.awk" 2>/dev/null) || true; echo "${out:-(no references)}"
```

**A shortlist, and what is left to ask** — the answers so far arrive as tags in `SHAPE`, `REQUIRE` and `EXCLUDE`; `count=N` is how many licences survived all of them, and the `splits:` block under it counts every tag the survivors carry, `n/N` apiece:

```bash
refs="${CLAUDE_PLUGIN_ROOT}/skills/licensing/references"; out=$(find "$refs" -maxdepth 1 -name '*.txt' 2>/dev/null | sort | SHAPE="<class, or empty for any>" REQUIRE="<tags>" EXCLUDE="<tags>" SPLIT=1 xargs awk -f "$refs/../scripts/filter.awk" 2>/dev/null) || true; echo "${out:-(no references)}"
```

That block is what decides the next question. A tag on `n/N` where `n` is neither `0` nor `N` divides the survivors, so asking about it is worth a round trip; a tag on `N/N` is one they all carry and a tag missing from the block entirely is one none of them do, and neither can narrow anything. Drop `SPLIT=1` where only the list is wanted.

**One licence, expanded** — every field, every tag joined to its label and its sentence:

```bash
refs="${CLAUDE_PLUGIN_ROOT}/skills/licensing/references"; out=$(awk -f "$refs/../scripts/explain.awk" "$refs/rules.yml" "$refs/<slug>.txt" 2>/dev/null) || true; echo "${out:-(no such licence)}"
```

**Two to four side by side** — the markdown table, and the rows that disagree:

```bash
refs="${CLAUDE_PLUGIN_ROOT}/skills/licensing/references"; out=$(awk -f "$refs/../scripts/compare.awk" "$refs/rules.yml" "$refs/<slug>.txt" "$refs/<slug>.txt" 2>/dev/null) || true; echo "${out:-(no such licence)}"
```

**What a licence leaves open** — one line per placeholder, whether the licence's own `how:` names it, and how many places it fills:

```bash
refs="${CLAUDE_PLUGIN_ROOT}/skills/licensing/references"; out=$(awk -f "$refs/../scripts/holders.awk" "$refs/<slug>.txt" 2>/dev/null) || true; echo "${out:-(nothing to fill in)}"
```

**The licence body, into a file** — written to a temporary and moved over the target only once it exits `0`, so a run that refuses leaves what is on disk alone:

```bash
refs="${CLAUDE_PLUGIN_ROOT}/skills/licensing/references"; t="/absolute/path/to/LICENSE.tmp"; YEAR="<year>" FULLNAME="<name>" awk -f "$refs/../scripts/write.awk" "$refs/<slug>.txt" > "$t" && mv "$t" "/absolute/path/to/LICENSE" && echo "write: ok" || { rc=$?; rm -f "$t"; echo "write: failed, exit $rc"; }
```

**The holes the write left, filled in** — over the written file, never over a reference, and through the same temporary-then-`mv`. Its `fill:` lines go to stderr and are the report of what happened, so they are not redirected away:

```bash
refs="${CLAUDE_PLUGIN_ROOT}/skills/licensing/references"; t="/absolute/path/to/LICENSE.tmp"; YEAR="<year>" FULLNAME="<name>" awk -f "$refs/../scripts/fill.awk" "/absolute/path/to/LICENSE" > "$t" && mv "$t" "/absolute/path/to/LICENSE" && echo "fill: ok" || { rc=$?; rm -f "$t"; echo "fill: failed, exit $rc"; }
```

`(no references)`, `(no such licence)` and `(nothing to fill in)` are covered in `## Rules`.

### Step 1 — Read the request

A licence **name** and an **action** arrive as free text, in either order, and both are optional. Match the action — it is a closed set of four — and whatever is left, minus filler like "the", "one" and "licence", is the name.

The verb decides the action:

| Action | The words that pick it | Where it goes |
|---|---|---|
| choose | which one, help me pick, recommend, suggest, what fits, what should I use — and a shape where a name would be, like "something permissive" | Step 3 |
| copy | add, write, put, apply, use, "license this" | Step 5 |
| compare | vs, versus, difference, differ, or, better | Step 6 |
| learn | everything else | Step 4 |

**An unclear action is learn.** Learning costs a paragraph and is undone by ignoring it; copying writes a legal instrument into a repository. So a bare `mit` is learn, and learn closes by offering the other three.

**Questions go one at a time, here and everywhere below.** One AskUserQuestion, one question in it, and the answer read before the next one is put — because every question this skill asks is worth less if the previous answer was not read first. The interview narrows the catalogue with each answer, so a question asked in a batch is a question asked of forty-seven licences when it could have been asked of nine; and a question the answers have already settled is one nobody should have to see.

**With nothing to go on** — no action and no name — ask the one question that everything else hangs off:

| Header | Question | Options |
|---|---|---|
| Intent | What do you want to do about licensing? | **Find one that fits — I will ask a few questions about the project** / Add a licence to this project / Understand one, or compare a few / Just show me the catalogue |

Bolded is the default and goes first. The catalogue is not printed before the question: it is forty-seven lines, and three of the four intents do not need it. "Just show me the catalogue" runs the index command, prints it, and stops — a finished answer, not a deferral.

Then, and only then, whatever that answer needs:

- **Find one that fits** → Step 3. No name is asked for — the questions are the name, and there are at most four of them.
- **Add a licence to this project** → Step 2 when the request already carried a name, and Step 3 when it did not. A licence nobody named is not one to write.
- **Understand one, or compare a few** → Step 2 when the request carried a name. When it did not, one more question — *Which one?* — offering **MIT** / Apache-2.0 / GPL-3.0, any slug through "Other", and *I don't know yet — ask me what fits*, which is Step 3.

**A licence the user names while asking to choose** is a **yardstick, not an answer** — "should I use MIT?" is the choose action with `mit` attached. The interview runs as it would have, and the shortlist afterwards says whether MIT survived the user's own answers and, where it did not, which question it fell out on. That is the useful thing to know about a licence someone is already leaning towards, and it is not the same as being told it is fine.

Complete when an action is settled and, unless the answer was the catalogue, either a name is in hand or the request is on its way to Step 3.

### Step 2 — Resolve the name to one licence

Run the candidates command with the user's words in `Q`. It prints every licence the words reach, closest first, and closes with `count=N tier=T` — `N` is how many licences reached the best tier anything reached, and lines below that tier are context rather than candidates. Branch on `N`:

| Last line | What happens |
|---|---|
| `count=1` | Take it. Open the answer with the full title and SPDX id, so a wrong match is visible in the first line |
| `count=2` … `count=4` | **AskUserQuestion**, one option per candidate, in the order printed, each labelled with its title and SPDX id |
| `count=5` or more | Say how many and what they share, then narrow with Step 3 — its four questions are what separates a family the name alone cannot. `gpl` prints five and `bsd` six, so this is the common case rather than the corner |
| `count=0`, or the words are a shape rather than a name | Step 3, with whatever those words already settle answered from them rather than asked again — "something permissive" is the first question answered |

Ask between candidates rather than picking one. A licence written into a repository is undone only with every contributor's agreement.

Complete when one licence — two to four, for compare — is named by slug, title and SPDX id, or the user has been asked which of the candidates they meant.

### Step 3 — Choose

The catalogue answers this one itself. Four questions, each of them a tag the frontmatters already carry, and the shortlist is whatever survives the ones that were asked — a filter over `references/`, not a recollection of which licence is "the permissive one with patents".

**One question, then the command, then the next question.** The shortlist command runs after every answer with `SPLIT=1`, and its two outputs decide what happens next: `count=N` says how many licences are left, and the `splits:` block says which of the remaining questions still divides them. This is the whole reason the questions are not batched — asked in a batch, all four go out against forty-seven licences; asked in turn, the second is asked of the thirteen the first left, and the fourth is usually not asked at all.

The four, in this order, which is the order of consequence:

| # | Header | Question | Option → the tag it adds |
|---|---|---|---|
| 1 | Derivatives | What should someone who builds on this be required to do? | **Keep the notice, nothing more** → `SHAPE=permissive` · Release their own changes under these same terms → `SHAPE=copyleft` · Nothing at all, not even the notice → `SHAPE=public-domain` · The notice plus a duty or two, like documenting what they changed → `SHAPE=other` |
| 2 | Reach | Where should "the same terms" stop? | The whole work built on it → `conditions:same-license` · Only the files they actually changed → `conditions:same-license--file` · Anything that merely links to it is exempt → `conditions:same-license--library` · **No preference** → nothing |
| 3 | Patents | What should it say about the contributors' patents? | Grant them expressly → `permissions:patent-use` · Say plainly that it grants none → `limitations:patent-use` · **No preference** → nothing |
| 4 | Trademark | Should it say it grants no rights in the project's name? | Yes, say so → `limitations:trademark-use` · **No preference** → nothing |

Question 1 is asked first and always: its options are the four classes the shape command prints in its first column, a bucket each licence is in exactly one of, computed from the whole conditions list — so a licence carrying `include-copyright` among other tags cannot pass as a permissive one. It is also the only answer most people arrive with. Where the user would rather see the buckets than answer for one, the shape command prints the whole catalogue by class, one line per licence. Where Step 1 or Step 2 already settled it — "something permissive" — take it as answered and do not ask it again.

**Before each of questions 2, 3 and 4, read the `splits:` block from the last run** and apply, in order:

| The block says | What happens |
|---|---|
| `count` is 3 or fewer | Stop asking. Three survivors fit in the handoff question below, and a fourth question that narrows three to two has cost a round trip to save the user a glance |
| No option's tag appears at `n/N` with `n` between `1` and `N-1` | Skip the question and say nothing about it. After `public-domain` nothing left carries `same-license` at all, so the Reach question would be four options of which three are empty |
| Some do | Ask it, and **offer only those options** — an option whose tag is missing from the block is one nobody left carries, and offering it is offering an empty answer. "No preference" is always offered, and is what makes two |

Carry the count into the wording: *Nine licences left. What should it say about the contributors' patents?* is a question with a visible cost, and the user can stop early on the strength of it.

`count=0` cannot happen while options are filtered that way, since every option offered is one at least one survivor carries. If it does, the last answer was an option the block did not support: drop that answer, say it was dropped, and re-run.

**The handoff**, once the questions run out or the count drops to three or fewer. Print every survivor — one line apiece, starred first, which is what choosealicense features and how the command already orders them — then **one question**:

| Header | Question | Options |
|---|---|---|
| Licence | Which of these? | The survivors, up to three, each by title and SPDX id; any other through "Other" |

And then, once a licence is named, **one more**:

| Header | Question | Options |
|---|---|---|
| Next | And then? | **Explain what it says** → Step 4 · Write it into this project → Step 5 · Show them side by side first → Step 6 · The name is enough |

Side by side takes every survivor where four or fewer survived, and the first four printed otherwise.

Where a licence came in as a yardstick from Step 1, say where it landed: it survived the answers, or it fell out, and on which question. Which question is read off the expanded command for that licence — its own tags are printed there, and an answer's tag is either among them or it is not. Name it: falling out on the trademark line is a different thing from falling out on copyleft.

**A shortlist is not advice.** It says which licences carry the tags the answers named, and every line of it traces to a frontmatter. Whether one of them suits a business, a contract already signed, or a codebase with other people's code in it is the question `## Rules` ends at a lawyer.

Complete when each answer has been turned into a tag and run through the shortlist command before the next question was put, no question was asked that the `splits:` block showed could not divide the survivors, the survivors and their count have been printed, and one licence is named by title and SPDX id.

### Step 4 — Learn

Run the expanded command for the licence. It prints every field and every tag already joined to its meaning; the report is prose around that output, in the order it comes out:

| From the output | Reported as |
|---|---|
| `title`, `spdx-id`, `nickname` | The heading — the full name, and the SPDX id that goes in a manifest |
| `description` | Verbatim, as choosealicense's own summary |
| `conditions`, `permissions`, `limitations` | Three lists, each tag as the label and one-sentence description the command printed. Conditions first — they are what the licence costs |
| `how` | What has to be filled in to use it, in choosealicense's own words. Where the holes command marks a placeholder `unnamed`, say so — `how:` is upstream's instruction, and for apache-2.0, ecl-2.0 and mulanpsl-2.0 it is not the whole list of blanks in the file |
| `note`, `using` | The caveat, where there is one, and two or three projects that use it |

Nothing in those lists is dropped for brevity: the command emits all of them, so a missing one is a missing line rather than an editorial choice.

**The licence text stays in its file.** Name that path, quote the clause the user asks about with `grep -n -m1 -A6 'patent' "$refs/<slug>.txt"`, and offer the copy action for the whole thing — that is what puts the words somewhere they are useful. GPL-3.0 and AGPL-3.0 are 36 KB each.

Close by naming the next move: copied into the project, compared with another, or — where this one turns out not to be what the project needs — put beside what the questions of Step 3 reach.

Complete when the licence is named by title and SPDX id, and every one of its conditions, permissions and limitations has been reported with the meaning `rules.yml` gives it.

### Step 5 — Copy

The licence is already settled — named by the user and resolved in Step 2, or arrived at through the answers in Step 3. A licence nobody named is not one to write, so a copy with no name behind it goes to Step 3 first.

**The text is written, never typed.** A licence's force is in its exact words, and two hundred lines of Apache recalled from memory is a plausible forgery rather than a licence. The bytes go from the reference file to the target file through the write command.

**Where it goes**: the directory the context block's first line names, as an absolute path in every command below — the working directory may be a subdirectory of it, and a `LICENSE` written there is a second licence nobody asked for. The filename is **`LICENSE`** whatever the licence is; choosealicense suggests `COPYING` for the GPLs, but hosts, licence detectors and a README's `## License` section all look for `LICENSE`.

When the context block found a licence file already there, ask first — **one AskUserQuestion, two options**: replace it with the new licence, or leave it and stop. Say that replacing discards what is on disk.

**What to substitute**: nothing, by hand, and nothing left silently blank either. Run the **holes** command for the slug before anything else. It prints every placeholder the licence carries and marks each one, and the mark says when it gets its value:

| Mark | What it is | Filled |
|---|---|---|
| `named` | `how:` asks for it — choosealicense's instruction for this licence, and the complete list. Fifteen of the forty-seven name anything at all | **Before the write.** The write refuses to run without a value, and refusing is what stops a blank notice from landing |
| `unnamed` | A hole `how:` does not mention: apache-2.0's and ecl-2.0's appendix, ncsa's `[projecturl]`, all three of mulanpsl-2.0's, whose `how:` names none of them | **After the write**, over the file on disk, with the fill command |

The write command fills what `how:` names and leaves every other bracket alone, because **a bracket `how:` does not name is licence text** — and the fill command afterwards touches only what the holes command listed, for the same reason. A bracket is a placeholder because it is on that list, never because of its shape: cecill-2.1 spells its own name `Ce[a] C[nrs] I[nria] L[ogiciel] L[ibre]` and blueoak-1.0.0 carries the markdown link `[Notices](#notices)`, and the holes command prints nothing at all for either.

**Where the values come from.** `[year]` and `[Year]` and `[yyyy]` take the context block's current year, and the `[fullname]` family its name for the copyright line. Everything else is **asked** — before the write, one AskUserQuestion per value and one value per question, each naming the licence that wants it and where it appears, and each answered before the next is put:

| Value | The candidate to offer first |
|---|---|
| `[project]`, `[Software Name]` | the repo directory's own name, from the context block's first line |
| `[email]` | the address from the context block, when it is set |
| the `[fullname]` family, when `user.name` is unset | none — see below |

The typed value goes in the tool's "Other" box, and every question carries **Leave the bracket standing** as its second option, which is also what makes two. Where there is no candidate to offer first — an unset name, an unset address — the pair is *Leave the bracket standing* and **Set it properly first**, which stops here so `git config user.name` can be set first, since a name that belongs in a copyright line belongs on the commits too.

**A name is never taken from the directory, from a manifest's author field or from the account name.** The copyright line says who owns the work, and a plausible wrong owner is worse than a question. A project name is a different thing: the directory it lives in is a candidate the user confirms, not an owner inferred.

Declining is an answer on both passes, and it means different things: an `unnamed` bracket stays in the file as the blank it is, while a `named` one stops the write, because the licence's own instruction says it is required.

**Run it** — the invocation in the commands block above, with the slug, the absolute paths and the values filled in. It closes with `write: ok` or with `write: failed, exit <n>`, and a failure says on the line above it what was wrong:

| Last line | What it means | What to do |
|---|---|---|
| `write: ok` | The body was written and moved into place | Verify it, below |
| exit `2` | `how:` names a placeholder with no value; stderr names each one, as `write: missing value for [fullname]` | The pre-write questions above were skipped, or one was declined. Ask for the value and run it again — never fill it in from the directory name, a manifest's author field or the account name |
| exit `3` | A placeholder survived into the output | Report it — the file was never moved into place |
| exit `4` | No frontmatter, no body, or `how:` names a placeholder the script does not know | A wrong slug, or a snapshot that has moved on. Check the slug against the index, then `## Rules` |

Any failure leaves the target exactly as it was: the body goes to a temporary and `mv` only runs on success, so a failed write cannot leave an empty `LICENSE` claiming terms the project does not have.

**Then fill what the write left.** When the holes command printed an `unnamed` line, the file on disk now carries that bracket. Ask for those values — again one question apiece, the same options as the table above with *Leave the bracket standing* always among them — and run the fill command with only the values that were answered. It prints one line per placeholder, `filled in` or `left standing`, with a count; it moves the file into place only on success, so a failed fill leaves the licence exactly as the write left it.

Two licences are worth knowing before asking:

- **apache-2.0** and **ecl-2.0** hold their brackets in the appendix, which is a template for the header of your *source* files rather than a blank in the licence itself. Filling it with the project's year and owner is ordinary, and so is leaving it — say which it is in the question, so the answer is about the appendix rather than about the licence.
- **mulanpsl-2.0** is the opposite. Its `how:` names nothing while its notice carries `[Year]`, `[name of copyright holder]` and `[Software Name]` twice over, so the write lands a file with no owner in it. This pass is not optional there.

**Prove it landed** — the last command greps for every placeholder the catalogue uses, not only the ones this licence named, so a bracket nobody asked about cannot pass unseen:

```bash
out=$(wc -l < /absolute/path/to/LICENSE 2>/dev/null) || true; echo "${out:-0} lines"
out=$(grep -n -m1 -i copyright /absolute/path/to/LICENSE 2>/dev/null) || true; echo "${out:-(no copyright line)}"
out=$(grep -n -E '\[(year|Year|yyyy|fullname|project|projecturl|email|Software Name|name of copyright (owner|holder))\]' /absolute/path/to/LICENSE 2>/dev/null) || true; echo "${out:-(none left)}"
```

Anything that grep prints is a bracket the user chose to leave. Read it back against that choice: a line it prints that nobody was asked about is a bug in this step, not a decision.

**Report** the path, the licence by title and SPDX id, that the text is verbatim from the catalogue snapshot with only its placeholders substituted — those `how:` named, filled by the write, and those it did not, filled afterwards from what the user gave — and the copyright line as it now reads, that one line and not a reprint. Name any bracket still standing, and say it is standing because the user left it. Then the two things the file alone does not do, as text to act on rather than edits made here:

- The manifest field, spelled out — `"license": "MIT"` for `package.json`, `license = "MIT"` for `Cargo.toml`. When the context block found a manifest declaring a *different* licence, say so plainly: a manifest and a `LICENSE` naming two different licences is the state that sends people to a lawyer.
- The README's `## License` section, where there is one to update.

Complete when `LICENSE` exists at that absolute path with a non-zero line count, every placeholder the holes command listed has been filled in or offered and declined, the placeholder grep prints `(none left)` or only brackets the user chose to keep, and the report names the path, the licence and the copyright line.

### Step 6 — Compare

Two to four licences — named by the user and resolved in Step 2, or the survivors of Step 3. Past four, ask which four.

Run the side-by-side command with them in the order they should read, left to right. It prints one block per group — conditions, then permissions, then limitations — holding the **union** of every tag appearing in any of them and nothing else, a cell reading `yes` or `—`, and row labels out of `rules.yml`:

| Conditions | MIT | GPL-3.0 |
|---|---|---|
| License and copyright notice | yes | yes |
| State changes | — | yes |
| Disclose source | — | yes |
| Same license | — | yes |

Print those blocks as they come. Under them the command lists the rows whose licences disagree, one `DIFFERS: <group> — <row>` line each — **name those rows and only those**, since they are the answer; the agreeing rows stay in the table so the reader can see nothing was left out. Then each licence's `description`, and any `note`, since a note is upstream flagging something the tags do not carry.

Complete when every tag appearing in any compared licence has a row, every cell is filled, and the disagreeing rows have been named apart from the agreeing ones.

## Rules

- One question per AskUserQuestion, and the answer read before the next question is put. Every question here is cheaper or unnecessary once the one before it is answered: the interview asks its second question of the survivors of the first, the placeholder questions of the licence that was actually chosen, and a question the previous answer settled is not asked at all
- Every statement about a licence traces to a line in `references/` — a frontmatter field, a tag `rules.yml` defines, or the licence's own words. Where a question needs something the catalogue does not hold — whether two licences are compatible, whether a project may relicense, whether a licence suits a particular business — say what the catalogue does say, name the gap, and point at a lawyer
- `(nothing to fill in)` is an ordinary answer and the common one: twenty-nine of the forty-seven carry no placeholder at all, and for those the copy is the write and nothing more. `(no references)` or `(no such licence)` means the catalogue is missing or the install is broken. Report that and print this command for the user to run; it rewrites a directory inside the installed plugin, so it is theirs to run deliberately: `bash ${CLAUDE_PLUGIN_ROOT}/skills/licensing/scripts/refresh-references.sh`. Answer from `references/` alone — the catalogue is a dated snapshot, and an answer from memory is indistinguishable from one that came from the files while being free to disagree with them
- A missing `rules.yml` takes the wording with it and nothing else. Run the expanded and side-by-side commands with the licence files alone, without `"$refs/rules.yml"` in front of them: every tag still gets its line and its row, as the bare slug it is, marked `(not defined in rules.yml)`. Say the dictionary is missing — inventing a definition for a slug is the one thing worse than printing it raw
- `grep`, `ls`, `find` and `wc` exit `1` when they find nothing, which here is an answer rather than a failure. Write every one of them as `out=$(<command> 2>/dev/null) || true; echo "${out:-(marker)}"`, the form the context block uses, so an ordinary finding cannot abort a step. The write and fill commands are the exception: their non-zero exits are real failures, they are what stops a bad `LICENSE` from landing, and they are reported rather than swallowed — never wrap either in `|| true`. Their `write:` and `fill:` lines go to stderr on purpose, so never send that to `/dev/null` either
- `references/SOURCE.md` carries the upstream commit and the date it was fetched. Read it when the answer turns on freshness — a licence about to land in a repository, or a user asking whether this is current

## Integration

- **Called by**: [`init`](../init/SKILL.md), for the licence half of setting up a project. `init` settles that a `LICENSE` is wanted; this skill asks which — through the questions of Step 3 when nobody has named one — writes it, and hands back the title, the SPDX id and the copyright line for `init`'s README and closing report
- **After this skill**: [`commit`](../commit/SKILL.md), for the commit that adds the file — `chore: add <SPDX-Id> licence`

---

# Links

- [references](references/) — the vendored choosealicense.com catalogue
- [refresh-references.sh](scripts/refresh-references.sh) — replaces it from upstream
- [index.awk](scripts/index.awk) — renders the catalogue listing
- [resolve.awk](scripts/resolve.awk) — ranks the licences a name reaches, and counts them
- [shape.awk](scripts/shape.awk) — classifies each licence by the conditions it charges
- [filter.awk](scripts/filter.awk) — the licences that survive a set of answers
- [explain.awk](scripts/explain.awk) — one licence, every field and every tag expanded
- [compare.awk](scripts/compare.awk) — the side-by-side table, and the rows that disagree
- [holders.awk](scripts/holders.awk) — every placeholder a licence carries, and whether its `how:` names it
- [write.awk](scripts/write.awk) — the licence body, with only what `how:` names filled in
- [fill.awk](scripts/fill.awk) — the holes the write left, filled in over the written file
- [choosealicense.com](https://choosealicense.com/licenses/)
- [init](../init/SKILL.md)
- [commit](../commit/SKILL.md)
