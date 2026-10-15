import { gitBlock } from "@/lib/git-data"
import type { GitCommit } from "@/lib/git-log"

// Parses the `git for-each-ref` block the skill embeds as
// <script type="text/plain" id="git-refs">. One ref per line, fields separated
// by \x1f: refname, short name, object, peeled object, upstream, track, HEAD.
export type Branch = {
  name: string
  remote: boolean
  oid: string
  upstream: string | null
  track: string // "", "[ahead 2]", "[behind 1]", "[ahead 2, behind 1]" or "[gone]"
  current: boolean
}

export type BranchHealth = Branch & {
  isDefault: boolean
  date: Date | null
  ahead: number // commits not on the default branch
  behind: number // default-branch commits not on this branch
  merged: boolean
  stale: boolean
  unpushed: boolean
  gone: boolean
}

export const STALE_DAYS = 90
const DAY = 24 * 60 * 60 * 1000

export function readGitRefs() {
  const raw = gitBlock("git-refs") ?? ""
  const branches: Branch[] = []
  let remoteHeadOid: string | null = null

  for (const line of raw.replace(/<\\\//g, "</").split("\n")) {
    if (!line) continue
    const [ref, short, oid, , upstream, track, head] = line.split("\x1f")
    if (ref.startsWith("refs/remotes/") && ref.endsWith("/HEAD")) {
      remoteHeadOid = oid
    } else if (ref.startsWith("refs/heads/") || ref.startsWith("refs/remotes/")) {
      branches.push({
        name: short,
        remote: ref.startsWith("refs/remotes/"),
        oid,
        upstream: upstream || null,
        track: track ?? "",
        current: head === "*",
      })
    }
  }
  return { branches, remoteHeadOid }
}

// Compares commits against the default branch, using only the embedded log.
export function makeComparer(
  branches: Branch[],
  remoteHeadOid: string | null,
  commits: GitCommit[]
) {
  const byHash = new Map(commits.map((commit) => [commit.hash, commit]))
  const ancestors = (oid: string) => {
    const seen = new Set<string>()
    const stack = [oid]
    while (stack.length) {
      const hash = stack.pop()!
      if (seen.has(hash)) continue
      seen.add(hash)
      byHash.get(hash)?.parents.forEach((parent) => stack.push(parent))
    }
    return seen
  }

  const locals = branches.filter((branch) => !branch.remote)
  const defaultBranch =
    locals.find((branch) => branch.name === "main") ??
    locals.find((branch) => branch.name === "master") ??
    locals.find((branch) => branch.oid === remoteHeadOid) ??
    locals.find((branch) => branch.current) ??
    null
  const defaultSet = defaultBranch ? ancestors(defaultBranch.oid) : new Set<string>()

  const compare = (oid: string) => {
    const own = ancestors(oid)
    let ahead = 0
    for (const hash of own) if (!defaultSet.has(hash)) ahead++
    let behind = 0
    for (const hash of defaultSet) if (!own.has(hash)) behind++
    return { ahead, behind, date: byHash.get(oid)?.date ?? null }
  }
  return { defaultBranch, compare }
}

export type Tag = { name: string; oid: string }

// Annotated tags point at a tag object; the peeled field is the commit.
export function readGitTags(): Tag[] {
  const raw = gitBlock("git-refs") ?? ""
  const tags: Tag[] = []
  for (const line of raw.replace(/<\\\//g, "</").split("\n")) {
    const [ref, short, oid, peeled] = line.split("\x1f")
    if (ref?.startsWith("refs/tags/")) tags.push({ name: short, oid: peeled || oid })
  }
  return tags
}

export function computeBranchHealth(
  branches: Branch[],
  remoteHeadOid: string | null,
  commits: GitCommit[],
  now = Date.now()
): BranchHealth[] {
  const { defaultBranch, compare } = makeComparer(branches, remoteHeadOid, commits)

  return branches.map((branch) => {
    const isDefault =
      !!defaultBranch &&
      (branch.name === defaultBranch.name ||
        (branch.remote && branch.name.endsWith(`/${defaultBranch.name}`)))
    const { ahead, behind, date } = compare(branch.oid)
    const ageDays = date ? (now - date.getTime()) / DAY : 0
    const merged = !isDefault && !!defaultBranch && ahead === 0
    return {
      ...branch,
      isDefault,
      date,
      ahead,
      behind,
      merged,
      stale: !isDefault && !branch.current && !merged && ageDays > STALE_DAYS,
      gone: branch.track.includes("gone"),
      unpushed:
        !branch.remote &&
        !isDefault &&
        (!branch.upstream || branch.track.includes("ahead")),
    }
  })
}
