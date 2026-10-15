import { gitBlock } from "@/lib/git-data"
// Parses the `git status --porcelain=v2 --branch` block the skill embeds as
// <script type="text/plain" id="git-status">.
export type GitStatus = {
  oid: string | null
  branch: string | null // null when HEAD is detached
  upstream: string | null
  ahead: number
  behind: number
  staged: number
  unstaged: number
  untracked: number
  conflicts: number
}

export function readGitStatus(): GitStatus {
  const raw = gitBlock("git-status") ?? ""
  const status: GitStatus = {
    oid: null,
    branch: null,
    upstream: null,
    ahead: 0,
    behind: 0,
    staged: 0,
    unstaged: 0,
    untracked: 0,
    conflicts: 0,
  }

  for (const line of raw.replace(/<\\\//g, "</").split("\n")) {
    if (line.startsWith("# branch.oid ")) {
      const oid = line.slice(13).trim()
      status.oid = oid === "(initial)" ? null : oid
    } else if (line.startsWith("# branch.head ")) {
      const head = line.slice(14).trim()
      status.branch = head === "(detached)" ? null : head
    } else if (line.startsWith("# branch.upstream ")) {
      status.upstream = line.slice(18).trim()
    } else if (line.startsWith("# branch.ab ")) {
      const match = line.match(/\+(\d+) -(\d+)/)
      if (match) {
        status.ahead = Number(match[1])
        status.behind = Number(match[2])
      }
    } else if (line.startsWith("1 ") || line.startsWith("2 ")) {
      const [x, y] = [line[2], line[3]]
      if (x !== ".") status.staged++
      if (y !== ".") status.unstaged++
    } else if (line.startsWith("u ")) {
      status.conflicts++
    } else if (line.startsWith("? ")) {
      status.untracked++
    }
  }
  return status
}
