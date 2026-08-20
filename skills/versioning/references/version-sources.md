# Version sources and bump signals

Shared by the `versioning` and `release` skills. Edit here, not in a SKILL.md.

## Where the current version lives

Check in order and use the **first match** as the authoritative version:

1. `package.json` → `"version": "X.Y.Z"`
2. `Cargo.toml` → `version = "X.Y.Z"`
3. `pyproject.toml` → `version = "X.Y.Z"`
4. `VERSION` file
5. Latest git tag → `vX.Y.Z` or `X.Y.Z`
6. `.claude-plugin/plugin.json` → `"version": "X.Y.Z"`
7. `.claude-plugin/marketplace.json` → `"version": "X.Y.Z"`

The first match decides *what the current version is*. Every other file in the
list that exists and carries a version still has to be **updated** to the new
version — a repo can hold several manifests that must not drift apart.

If nothing matches, ask the user for the current version (suggest `0.1.0` for a
new project).

## Choosing the bump

Read the conventional commits since the last version tag:

```bash
git describe --tags --abbrev=0 2>/dev/null
git log <last-tag>..HEAD --oneline --no-merges
```

| Signal                                      | Bump type |
|---------------------------------------------|-----------|
| `BREAKING CHANGE:` footer or `!` after type | **Major** |
| `feat:` commits present                     | **Minor** |
| `fix:` commits only                         | **Patch** |
| Mixed `feat` + `fix`, no breaking change    | **Minor** |
| Only `chore` / `docs` / `ci` / `build`      | **Patch** |

An explicit version or bump type from the user always wins over this table.

On major version `0`, the public API is considered unstable: a breaking change
is conventionally a **minor** bump (`0.2.2` → `0.3.0`), not a jump to `1.0.0`.
Say so rather than silently deciding.

Pre-release versions (`1.0.0-alpha.1`) are valid — support them when asked.
