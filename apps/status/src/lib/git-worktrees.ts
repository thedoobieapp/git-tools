import { gitBlock } from "@/lib/git-data"
// Parses `git worktree list --porcelain`, embedded by the skill as
// <script type="text/plain" id="git-worktrees">. Entries are separated by a
// blank line; the first entry is the main worktree.
export type Worktree = {
  path: string
  oid: string | null
  branch: string | null // null when detached or bare
  detached: boolean
  bare: boolean
  main: boolean
  locked: boolean
  prunable: boolean
}

export function readGitWorktrees(): Worktree[] {
  const raw = gitBlock("git-worktrees") ?? ""
  return raw
    .replace(/<\\\//g, "</")
    .split(/\n\s*\n/)
    .map((block) => block.trim())
    .filter(Boolean)
    .map((block, index) => {
      const worktree: Worktree = {
        path: "",
        oid: null,
        branch: null,
        detached: false,
        bare: false,
        main: index === 0,
        locked: false,
        prunable: false,
      }
      for (const line of block.split("\n")) {
        if (line.startsWith("worktree ")) worktree.path = line.slice(9)
        else if (line.startsWith("HEAD ")) worktree.oid = line.slice(5)
        else if (line.startsWith("branch ")) {
          worktree.branch = line.slice(7).replace(/^refs\/heads\//, "")
        } else if (line === "detached") worktree.detached = true
        else if (line === "bare") worktree.bare = true
        else if (line.startsWith("locked")) worktree.locked = true
        else if (line.startsWith("prunable")) worktree.prunable = true
      }
      return worktree
    })
}
