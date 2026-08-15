# Changelog

All notable changes to the `git-tools` plugin will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.1.0/),
and this plugin adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

Versions here are the plugin's own, as recorded in
`.claude-plugin/plugin.json`.

## [Unreleased]

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
