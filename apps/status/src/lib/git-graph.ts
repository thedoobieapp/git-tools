import type { GitCommit } from "@/lib/git-log"

export type GraphRow = {
  commit: GitCommit
  column: number
  // Lanes entering the row from above, and the lane each parent leaves by.
  before: (string | null)[]
  parentColumns: number[]
}

// Assigns each commit a lane. `commits` must be newest first (the log's own
// topological order). A lane holds the hash it is waiting for; parents that are
// not in the list are dropped so lanes do not stay open forever.
export function layoutGraph(commits: GitCommit[]) {
  const known = new Set(commits.map((commit) => commit.hash))
  const lanes: (string | null)[] = []
  const rows: GraphRow[] = []
  let width = 1

  const freeLane = () => {
    const free = lanes.indexOf(null)
    if (free !== -1) return free
    lanes.push(null)
    return lanes.length - 1
  }

  for (const commit of commits) {
    const before = [...lanes]
    let column = lanes.indexOf(commit.hash)
    if (column === -1) column = freeLane()
    // Every lane waiting for this commit ends here.
    lanes.forEach((hash, index) => {
      if (hash === commit.hash) lanes[index] = null
    })

    const parents = commit.parents.filter((parent) => known.has(parent))
    const parentColumns = parents.map((parent, index) => {
      const existing = lanes.indexOf(parent)
      if (existing !== -1) return existing
      const target = index === 0 ? column : freeLane()
      lanes[target] = parent
      return target
    })

    while (lanes.length && lanes[lanes.length - 1] === null) lanes.pop()
    width = Math.max(width, before.length, lanes.length, column + 1)
    rows.push({ commit, column, before, parentColumns })
  }
  return { rows, width }
}
