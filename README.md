# Git Tools

A [Claude Code plugin](https://code.claude.com/docs/en/plugins.md) covering the
everyday git workflow — putting a project under version control, committing,
branching, keeping a changelog, versioning and cutting releases.

Each skill is grounded in a published spec rather than in house habit:
[Conventional Commits 1.0.0](https://www.conventionalcommits.org/en/v1.0.0/),
[Conventional Branch 1.0.0](https://conventional-branch.github.io/),
[Keep a Changelog 1.1.0](https://keepachangelog.com/en/1.1.0/) and
[Semantic Versioning 2.0.0](https://semver.org/spec/v2.0.0.html). The specs live
once in [skills/docs/](skills/docs/), so no two skills can drift
apart on what a `feat` commit means or where a version number is kept.

Every decision that is the user's to make — the branch type, where a new repo
gets pushed, what lands in a commit, the version bump, whether a tag gets
pushed — goes through a multiple choice question, never a silent guess and
never a typed reply in prose.

## Skills

| Skill | What it does | Follows |
|---|---|---|
| [`init`](skills/init/SKILL.md) | Reports whether the project root is already a repo, is nested inside a parent one, or is untracked. For an untracked root: asks everything in one question before anything is created — the base branch, the remote URL, which of the editor and tool folders actually present (`.vscode/`, `.idea/`, `.zed/`, `.fleet/`, `.claude/`, a `pm` docs root) git should ignore, and whether to write the `.gitignore` — then runs `git init`, wires up `origin` when a URL was given, and drafts the file, printing it in full in the closing report. The remote is optional and never guessed, an unreachable URL is a warning rather than a refusal, and an `origin` that already exists is left alone. An existing `.gitignore` is appended to, never redrafted | [gitignore-patterns](skills/docs/gitignore-patterns.md) |
| [`commit`](skills/commit/SKILL.md) | Screens the files about to enter the commit for secrets, dependency directories, build output and OS cruft; groups the working set into the fewest commits that pass the "together test"; drafts a conventional message per group and confirms each one before it lands | [Conventional Commits 1.0.0](skills/docs/conventional-commits-1.0.0.md) |
| [`branch`](skills/branch/SKILL.md) | Picks the prefix (`feat/`, `fix/`, `hotfix/`, `release/`, `chore/`), validates the name against the spec, and creates and switches to the branch | [Conventional Branch 1.0.0](skills/docs/conventional-branch-1.0.0.md) |
| [`changelog`](skills/changelog/SKILL.md) | Creates a `CHANGELOG.md`, adds entries to `## [Unreleased]`, or promotes that section into a versioned one. Entries are written for humans, not copied from commit subjects | [Keep a Changelog 1.1.0](skills/docs/keep-a-changelog-1.1.0.md) |
| [`versioning`](skills/versioning/SKILL.md) | Detects the current version and every file carrying it, derives the bump from the conventional commits since the last tag, updates all of them together, and tags | [Semantic Versioning 2.0.0](skills/docs/semantic-versioning-2.0.0.md) |
| [`release`](skills/release/SKILL.md) | The whole sequence in one pass: bump, changelog promotion, every version file updated, one `chore: release X.Y.Z` commit and one annotated tag — behind a single confirmation. Pushes only when explicitly asked; local-only is the default | all of the above |

`versioning` and `changelog` remain useful on their own — bumping a version
without cutting a release, or logging work under `Unreleased` as it happens.
When the goal is an actual release, `release` replaces running both by hand and
produces one commit instead of a split one.

## Requirements

- [Claude Code](https://code.claude.com/docs/en/overview.md) with plugin support
- `git` on `PATH`

No runtime, no dependencies to install: the plugin is Markdown. Running the
test suite needs nothing more — bash and `git`, and the bash macOS ships is
new enough.

## Installation

From the marketplace, inside Claude Code:

```
/plugin marketplace add thedoobieapp/skills
/plugin install git-tools@the-doobie-app-skills
```

From a local checkout of this repository, for one session:

```bash
claude --plugin-dir /path/to/git-tools
```

To load a checkout in every session, place it at `~/.claude/skills/git-tools/`;
it is picked up on the next start as `git-tools@skills-dir`.

## Usage

Ask for the work in your own words — each skill's description covers the phrasings
people actually use:

```
set up git here
commit my changes
start working on OAuth login
what changed since the last release?
what should the next version be?
release this
```

Or invoke a skill directly:

```
/git-tools:init
/git-tools:commit
/git-tools:branch
/git-tools:changelog
/git-tools:versioning
/git-tools:release
```

A typical cycle:

```
/git-tools:init        # once, when the project has no repo
/git-tools:branch      # feat/oauth-login
   … work …
/git-tools:commit      # one or more conventional commits
/git-tools:changelog   # entries under ## [Unreleased]
/git-tools:release     # bump + changelog + commit + tag, one confirmation
```

Every skill that needs a repo checks for one first, and points at `init` instead
of failing when there isn't one.

## Repository layout

```
git-tools/
├── .claude-plugin/
│   └── plugin.json                        # Plugin manifest (name, version, metadata)
├── skills/
│   ├── init/SKILL.md                      # One directory per skill
│   ├── commit/SKILL.md
│   ├── branch/SKILL.md
│   ├── changelog/SKILL.md
│   ├── versioning/SKILL.md
│   ├── release/SKILL.md
│   └── docs/                              # Specs and tables, shared by every skill
│       ├── SKILL.md                       # Lists and reads the files beside it
│       ├── commit-type-mapping.md
│       ├── conventional-branch-1.0.0.md
│       ├── conventional-commits-1.0.0.md
│       ├── gitignore-patterns.md
│       ├── keep-a-changelog-1.1.0.md
│       ├── semantic-versioning-2.0.0.md
│       └── version-sources.md
├── tests/                                 # The plugin's own suite — see Development
│   ├── run-tests.sh
│   ├── lib/harness.sh                     # desc/assert vocabulary, per-test temp dirs
│   └── cases/                             # One file per area, run in name order
│       ├── 10-manifest.sh
│       ├── 20-skill-frontmatter.sh
│       ├── 30-skill-context.sh
│       └── 40-self-contained.sh
├── CHANGELOG.md
├── LICENSE
└── README.md
```

A `SKILL.md` is frontmatter (`name`, `description`, `allowed-tools`, `model`)
followed by instructions. The `description` is what Claude matches a request
against, so it carries the trigger phrasings; `allowed-tools` is scoped to the
git subcommands that skill actually needs.

## References

Reference material lives once in `skills/docs/` rather than once per
skill, so several skills cite the same copy of a spec without the copies
drifting. The directory carries a small `SKILL.md` of its own, which is what
makes it install alongside the skills rather than be left behind; that skill
only lists the documents beside it and reads the one asked for. Skills read the
files as `${CLAUDE_PLUGIN_ROOT}/skills/docs/<file>.md` and link to them as
`../docs/<file>.md`.

| File | Contents | Read by |
|---|---|---|
| [`conventional-commits-1.0.0.md`](skills/docs/conventional-commits-1.0.0.md) | The commit message spec | `commit` |
| [`conventional-branch-1.0.0.md`](skills/docs/conventional-branch-1.0.0.md) | The branch naming spec | `branch` |
| [`keep-a-changelog-1.1.0.md`](skills/docs/keep-a-changelog-1.1.0.md) | The changelog format | `changelog`, `release` |
| [`semantic-versioning-2.0.0.md`](skills/docs/semantic-versioning-2.0.0.md) | The versioning spec | `versioning` |
| [`commit-type-mapping.md`](skills/docs/commit-type-mapping.md) | Which commit type becomes which changelog category | `changelog`, `release` |
| [`version-sources.md`](skills/docs/version-sources.md) | Where a version lives (`package.json`, `Cargo.toml`, `pyproject.toml`, `VERSION`, git tags, plugin and marketplace manifests), in precedence order, and the bump table | `versioning`, `release` |
| [`gitignore-patterns.md`](skills/docs/gitignore-patterns.md) | What should never be committed, by category | `init`, `commit` |

## Development

Edit a `SKILL.md` and reload the plugin — there is nothing to build.

Validate the manifest and the skills:

```bash
claude plugin validate .
```

Try a change before shipping it:

```bash
claude --plugin-dir .
```

Two constraints worth knowing before editing. Both were real bugs, and both are
now held down by a test — read the test before working around it:

- **`## Context` commands run at load time**, and a non-zero exit aborts the
  whole skill. Every git command in a context block needs a fallback
  (`|| echo "(no repo)"`), or the skill breaks in a directory that isn't a repo
  yet. See `0.2.0` in the [changelog](CHANGELOG.md); guarded by
  [`30-skill-context.sh`](tests/cases/30-skill-context.sh).
- **Frontmatter is YAML.** A `description` containing `: ` must be quoted, or
  the parse fails silently and the skill loses every frontmatter field,
  including its own trigger description. See `0.2.1`; guarded by
  [`20-skill-frontmatter.sh`](tests/cases/20-skill-frontmatter.sh).

### Tests

The plugin carries its own suite, in [tests/](tests/). It reaches for nothing
outside the plugin directory — no marketplace, no sibling plugins, no fixtures
elsewhere on disk — so it runs the same from a checkout of this repository, from
`~/.claude/skills/git-tools/`, or from a copy installed by the marketplace. One
of the tests proves that by copying the plugin somewhere on its own and running
against the copy.

```bash
./tests/run-tests.sh               # everything
./tests/run-tests.sh context       # only case files whose name matches
VERBOSE=1 ./tests/run-tests.sh     # also print what each passing test established
```

The run exits 0 only if every test passed. **29 tests across 4 case files, all
green** as of `0.4.0`.

| Case file | Tests | What it holds the plugin to |
|---|---|---|
| [`10-manifest.sh`](tests/cases/10-manifest.sh) | 8 | `plugin.json` parses, sits at `.claude-plugin/`, names the plugin `git-tools`, carries description, author, license and keywords, and a version that is a SemVer number; `CHANGELOG.md` opens as Keep a Changelog, keeps an `Unreleased` section, and its latest release is the version the manifest declares; `claude plugin validate` passes |
| [`20-skill-frontmatter.sh`](tests/cases/20-skill-frontmatter.sh) | 7 | Every `SKILL.md` opens with a `---` block, its frontmatter `name` is its directory name, it declares a `description`, `allowed-tools` and a `model`, every git subcommand it runs at load time is in `allowed-tools`, and no unquoted value contains `': '`; the plugin ships exactly six skills |
| [`30-skill-context.sh`](tests/cases/30-skill-context.sh) | 7 | Every `## Context` command in every skill exits 0 in five project states — outside a repo, a repo with no commits, one with commits but no tags, one with commits, a tag and a dirty tree, and a detached HEAD. Plus two guards: the count of context commands, and the set of them that would break under `pipefail` |
| [`40-self-contained.sh`](tests/cases/40-self-contained.sh) | 7 | Every link and `${CLAUDE_PLUGIN_ROOT}` path resolves and stays inside the plugin; references and skills pair up both ways; no skill or reference names a sibling plugin or a marketplace path; every shell file parses as bash and avoids bash 4 and GNU-only constructs; the plugin — and the suite itself — still work from a standalone copy |

How the harness behaves, which is what makes a failure readable:

- Each test is a `test_*` function run in a subshell whose working directory is
  a fresh temp dir, so no test sees another's state.
- A failure reports the `desc` string — the contract that broke — not a line
  number, followed by expected/actual and any output from what it ran.
- The plugin tree is fingerprinted before and after the run. A suite that wrote
  into the plugin fails the run, because it would corrupt an installed copy.
- Written for bash 3.2 (the macOS system bash) and BSD userland: no associative
  arrays, no `mapfile`, no GNU-only flags.

To add a test, write a `test_*` function in the case file that fits, open it
with `desc "the contract in one line"`, and assert with the vocabulary in
[`lib/harness.sh`](tests/lib/harness.sh) (`assert_eq`, `assert_ok`,
`assert_contains`, `assert_matches`, `assert_file`, …). `run_cases` at the
bottom of the file discovers it — there is nothing to register.

## Contributing

- Run `./tests/run-tests.sh` before proposing a change; a change to a skill's
  frontmatter or `## Context` block is exactly what the suite exists to catch.
- Commit with [Conventional Commits](skills/docs/conventional-commits-1.0.0.md) —
  the plugin is used on itself, so `/git-tools:commit` is the intended path.
- Log user-visible changes under `## [Unreleased]` in [CHANGELOG.md](CHANGELOG.md).
- Cut releases with `/git-tools:release`. The version lives in
  [`.claude-plugin/plugin.json`](.claude-plugin/plugin.json), and the marketplace
  entry in the monorepo must be moved with it — a `plugin.json` and a
  `marketplace.json` out of sync is a bug.

## Changelog

See [CHANGELOG.md](CHANGELOG.md).

## License

[MIT](LICENSE) © The Doobie Crew
