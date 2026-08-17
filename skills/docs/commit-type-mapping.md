# Commit type → changelog category

Shared by the `changelog` and `release` skills. Edit here, not in a SKILL.md.

| Commit type / signal        | Changelog category |
|-----------------------------|--------------------|
| `feat:`                     | Added              |
| `fix:`                      | Fixed              |
| `refactor:`, `perf:`        | Changed            |
| `chore:`, `build:`, `ci:`   | Changed            |
| Marked as deprecated        | Deprecated         |
| Removed functionality       | Removed            |
| Security patches            | Security           |

`docs:`, `test:` and `style:` commits usually produce **no** changelog entry —
include one only when the change is visible to a user of the project.

Only emit categories that have entries; never write an empty section.

## Writing the entries

Entries are for humans, not machines. Translate the commit into what changed
from the reader's point of view:

- Not `feat(release): add release skill` — instead `` `release` skill — bumps the
  version, promotes the changelog, commits and tags in one pass ``
- Lead with the thing that changed, then the effect
- Name the component in backticks when the project has more than one
- Several commits that add up to one user-visible change collapse into **one**
  entry; one commit that changes two unrelated things splits into **two**
