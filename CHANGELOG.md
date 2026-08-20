# Changelog

All notable changes to the `git-tools` plugin will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.1.0/),
and this plugin adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

Versions here are the plugin's own, as recorded in
`.claude-plugin/plugin.json`.

## [Unreleased]

### Added

- A seventh skill, `licensing` — it explains, compares and writes open-source
  licences from the plugin's own verbatim snapshot of the choosealicense.com
  catalogue: 47 licence texts plus the `rules.yml` tag dictionary, with a
  `SOURCE.md` recording the upstream commit and a refresh script that replaces
  the snapshot wholesale. A `LICENSE` is a legal instrument whose force is in
  its exact words, so nothing is ever written from memory. Four actions: copy a
  licence into a project, learn what one permits, requires and limits, compare
  two, or choose one by answering for what the project needs.
- Nine awk scripts under `skills/licensing/scripts/` carry the catalogue work
  the skill used to do inline and judge in prose, where the same request could
  land differently twice running. `resolve.awk` ranks a free-text name into
  tiers and reports how many reached the best one, `filter.awk` narrows a
  shortlist and counts every tag that still splits it, `explain.awk` and
  `compare.awk` join a tag to its meaning, `holders.awk` finds what a licence
  leaves open, and `write.awk` and `fill.awk` go through a temporary moved over
  the target only on exit 0, so a refused run leaves what is on disk alone.
- `commit` screens the files about to enter a commit with `scripts/screen.awk`
  rather than prose. It sees every candidate path and knows the file sizes,
  which reading a list of paths cannot tell you, and `git check-ignore` is no
  longer needed because `ls-files --exclude-standard` has already dropped what
  `.gitignore` covers.

### Changed

- Every reference now sits in a `references/` folder beside the `SKILL.md` that
  reads it. The shared `skills/docs/` directory is gone, and the `docs` skill
  that existed only to make that directory install with the plugin goes with it
  — a skill's own folder already installs. `release` keeps none of its own and
  reads three across: `version-sources` from `versioning`,
  `commit-type-mapping` and `keep-a-changelog` from `changelog`. Its Rules
  section says so, so a reference that fails to load points at the right folder
  rather than at a directory that no longer exists.
- The test suite followed the references into their new folders. The harness no
  longer names a shared `skills/docs/`; it finds every `*/references/*.md`
  instead, and the completeness check now asks that *some* `SKILL.md` names a
  reference rather than the one sitting beside it, because `release` owns none
  and reads three across. The skill list swapped `docs` for `licensing`, the
  context-command count went from 35 to 43, and the set of commands that would
  break under `pipefail` went from four to none — the `out=$(…) || true` rewrite
  swallows a pipeline's status whatever `pipefail` says, so that guard now holds
  the set at empty rather than at four. `CHANGELOG.md` is exempt from the link
  check: an entry describing a directory that has since been removed names it
  correctly, and holding a history to today's tree would force every past entry
  to be rewritten by whoever moves a file next.
- `init` no longer carries an MIT template of its own. Its License question
  offers MIT, Apache-2.0 and GPL-3.0 with a one-line gloss each, plus "Show me
  all of them", and the chosen answer is handed to `licensing` rather than
  written by `init` itself.
- `init` now initializes a **local** repository only. The remote question, the
  `git ls-remote` reachability check, the `git remote add origin`, the
  unreachable-URL follow-up and the closing `git push -u` hint are all gone,
  along with the remote lines in the context block and the `git remote` /
  `git ls-remote` grants in `allowed-tools`. A repo with no remote is reported
  as finished rather than as half-set-up.
- `init` now settles all three starter files — `.gitignore`, `README.md` and
  `LICENSE` — instead of only the `.gitignore`, and asks in two passes instead
  of one. The first is four questions in a single call: the base branch, then
  one question per file, the ones already on disk before the ones that are not.
  A file that exists offers leave it as it is, amend it with the template
  entries it lacks, delete and recreate it from the template, or delete it; a
  file that does not offers create it from the template adapted to this project,
  create it from the plain template, or skip it — and the adapted option is
  withheld when the root holds nothing to adapt to, since it would produce
  exactly what the plain one does. Existing files are asked about first because
  that is the only place in the skill where content can be overwritten or
  deleted, and both destructive options say up front that nothing is committed
  yet, so git has no copy to recover from. The second pass runs after `git init`
  and carries only what a template cannot answer: which editor and tool folders
  to ignore, and which licence — MIT, or any other named through "Other". The
  README invents nothing, with unanswered placeholders left standing rather than
  filled with plausible fiction, and a licence is written verbatim or not at
  all. The copyright line takes its year and name from the context block on
  every path, and an unset `user.name` is asked for rather than guessed.
- `init` ships two starter templates in `skills/init/templates/` — a
  stack-agnostic `.gitignore` and a README skeleton — written as they are when
  the user picks the template option. They sit with the skill rather than with
  the references it reads, which hold material a skill reads to decide
  something, not files it writes.

### Fixed

- A context block reported an empty git result as though there were no repo.
  The old form, `git … 2>/dev/null || echo "(no repo)"`, only spoke up when git
  failed: on a detached HEAD `branch --show-current` exits 0 and prints
  nothing, so the block showed a blank line, and a repo with no tags printed
  nothing at all. Every context line now runs as
  `out=$(…) || true; echo "${out:-(marker)}"`, and the markers name the state
  they found — no branch, no tags, nothing staged, working tree clean.
- Each skill's Rules section now carries the same three constraints for the
  commands it runs during the task. Guard every exit, because several git
  commands report an ordinary answer through a non-zero status: `check-ignore`
  exits 1 for "not ignored", `config --get` exits 1 for unset, `rev-parse HEAD`
  exits 128 before the first commit. Do not re-run a context command bare to
  confirm what is already printed. And never leave a glob unquoted — zsh aborts
  on an unmatched one during expansion, which no `2>/dev/null` can suppress.

## [0.6.0] - 2026-08-17

### Added

- `.claude-plugin/marketplace.json` — the repository now publishes itself. Its
  one entry is sourced from `./`, the repository root, so the plugin and the
  catalogue listing it are the same directory. Installation is
  `/plugin marketplace add thedoobieapp/git-tools` followed by
  `/plugin install git-tools@git-tools`, with no other marketplace to add first.
- A fifth case file, `15-marketplace.sh`, holding the marketplace manifest to
  its schema and to the plugin manifest beside it. The pairing matters because
  the version is now written twice and `plugin.json` wins at install time: an
  entry left behind at the old number advertises a version nobody receives, and
  `claude plugin validate` reports that as a warning while still exiting `0`.
  It also checks the README's install lines against the name the manifest
  actually declares.

### Changed

- `version-sources` now says where a version lives inside a `marketplace.json`
  — the `version` of the matching entry in `plugins[]`, not a top-level field —
  and spells out the consequence of letting the two manifests drift.
- Installation in the README is the self-hosted marketplace. The
  `thedoobieapp/skills` route is no longer documented.

## [0.5.0] - 2026-08-17

### Added

- A seventh skill, `docs`, in the reference directory itself. Its job is to make
  that directory install with the plugin the way a skill does; asked for
  directly, it lists the documents beside it and reads the one wanted. It never
  edits a reference and never does the work a spec describes.

### Changed

- Reference material moved from `references/` at the plugin root to
  `skills/docs/`, so everything a skill reads at run time now lives under
  one directory. Skills read the files as
  `${CLAUDE_PLUGIN_ROOT}/skills/docs/<file>.md` and link to them as
  `../docs/<file>.md`.
- The test that proves no reference is dead weight now searches only the
  `SKILL.md` files rather than the whole skills directory. The references sit
  under that directory and cross-link each other, so the wider search would
  have found every file named by a sibling and passed on its own footprints.

## [0.4.0] - 2026-08-15

### Changed

- `init` now asks where the repository will be pushed, in the same question as
  the base branch. The URL is never inferred — not from `package.json`, not
  from a `gh` config, not from the directory name — because the remote is the
  one fact about a new repo that only the person creating it knows, and a
  wrong one is worse than none. It is typed into the question's "Other" field,
  or the step is skipped; skipping is a finished answer, not a deferral.
- A URL is checked with `git ls-remote` before `origin` is wired up, and one
  that does not answer is reported and handed back rather than refused. A
  repository nobody has created on the host yet, a private one, and a typo are
  indistinguishable from the client side, so the user decides whether to keep
  it, retype it or drop it.
- A project that is already a repo but has no remote is offered the same
  question; one that already has an `origin` is left exactly as it is. Nothing
  is ever pushed — the closing report prints `git push -u origin <branch>` as
  text, to be run once `commit` has made the first commit.
- `init` now asks everything in a single question, before anything is created.
  The base branch, the remote, which editor and tool folders git ignores, and
  whether to write the `.gitignore` are all answerable from the context the
  skill already gathered at load, and none of them depends on another, so
  spending a separate round trip on each only made the skill slower to get
  through. A question is included only when there is something to decide: no
  editor folders on disk, no folder question; a `.gitignore` already there, no
  `.gitignore` question.
- The drafted `.gitignore` is written on the strength of that answer and printed
  in full in the closing report, rather than printed first and written second.
  Nothing lands unseen — the reading moved from before the write to after it —
  and "show me the draft first" is still there for anyone who wants the old
  order. Appending to an existing `.gitignore` no longer asks at all, since the
  appended lines are exactly the folders just chosen.

## [0.3.1] - 2026-08-14

### Changed

- Every skill now links to the reference files it reads and to the skills it
  hands off to. Each one previously named them in prose only, leaving the
  reader to go looking; each now ends in a `Links` section pointing at the
  references, and every Integration bullet carries a path to the skill it
  names.

## [0.3.0] - 2026-08-06

### Changed

- `init` asks whether git should ignore the editor and tool folders it finds,
  instead of deciding it silently. Before drafting the `.gitignore` it lists
  the folders actually present in the root — `.vscode/`, `.idea/`, `.zed/`,
  `.fleet/`, `.claude/`, plus any `pm` docs root — and asks in one multi-select
  which of them git should ignore, recommending that the shared ones stay
  tracked. When a `.gitignore` already exists the step still runs and only the
  missing lines are appended; the file is never redrafted.

## [0.2.1] - 2026-08-03

### Changed

- Every decision now goes through `AskUserQuestion`, not only the main
  confirmation: an ambiguous branch type, the changelog mode, a missing version
  file, releasing from the wrong branch. Each skill's Rules section enumerates
  its own decision points, so the constraint holds even when only part of the
  file is in context.

### Fixed

- `release` loaded with no metadata at all. Its unquoted `description`
  contained `` `chore: release X.Y.Z` ``, and YAML reads an embedded `: ` as a
  nested mapping, so the parse failed and every frontmatter field — `name`,
  `description`, `allowed-tools`, `model` — was silently dropped. The skill
  could never be triggered by its description. Shipped broken in 0.2.0.
- The plugin manifest listed `contact@thedoobieapp.com` where the rest of the
  marketplace used `contact@thedoobie.app`. Both now agree.

## [0.2.0] - 2026-08-03

### Added

- `init` skill — checks whether the project root is already a git repo, and
  when it isn't, confirms the base branch name (default `master`), runs
  `git init`, and offers a starter `.gitignore`.
- `release` skill — cuts a release in one pass: decides the SemVer bump,
  promotes the `Unreleased` changelog section, updates every version-carrying
  file, then makes a single `chore: release X.Y.Z` commit and an annotated tag.
  Asks once, and only pushes when you say so.

### Changed

- `versioning` and `changelog` read the version-source list, bump table and
  commit-type mapping from shared `references/` files instead of keeping their
  own copies, so `release` cannot drift from them.
- All reference material lives in one `references/` folder at the plugin root
  instead of a folder per skill, so every skill cites the same copy of each
  spec.

### Fixed

- Reference links pointed at an Obsidian vault path
  (`projects/ai/plugins/opus-ordinatum/…`) that does not exist in this repo,
  and `commit`'s link to the gitignore patterns dropped its directory. Every
  link now resolves.
- Skills aborted at load time whenever a `## Context` command exited non-zero:
  `init` could never run outside a repo, and `commit` and `branch` broke on a
  repo with no commits. Context commands now fall back to a readable marker,
  and a skill reports a missing repo by pointing at `init` instead of failing
  with an opaque harness error.

## [0.1.0] - 2026-07-23

### Added

- `git-tools` plugin — four skills covering the everyday git workflow:
  `commit` (Conventional Commits 1.0.0), `branch` (Conventional Branch 1.0.0),
  `changelog` (Keep a Changelog 1.1.0) and `versioning` (Semantic Versioning
  2.0.0).
