---
name: docs
allowed-tools: Read, Glob
description: List and read the reference documents the other git-tools skills are written against — the commit, branch, changelog and versioning specs, plus the lookup tables they share. Use when the user asks which specs git-tools follows, wants to read one of them directly, or says 'show me the git-tools references', 'what spec does the commit skill follow', 'list the git-tools docs'.
model: haiku
---

# Docs SKILL

The reference material every other git-tools skill reads lives in this
directory. It sits inside `skills/` and carries this file so that it installs
with the plugin the way a skill does, and so it can be asked for directly.

## Steps

1. Glob `${CLAUDE_PLUGIN_ROOT}/skills/docs/*.md`, excluding this file.
2. Report each document by filename with a one-line summary of what it covers,
   read from its opening heading.
3. If the user named one of them, read that file and answer from it. Otherwise
   stop at the list — do not read every document.

## Notes

- This skill only lists and reads. It never edits a reference document, and it
  never carries out the work a spec describes; the skill that owns that work
  (`commit`, `branch`, `changelog`, `versioning`, `release`, `init`) does.
