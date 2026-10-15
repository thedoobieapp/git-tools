import { gitBlock } from "@/lib/git-data"

// The status skill appends <script type="text/plain" id="git-meta"> holding the
// repository name on line one and the snapshot timestamp on line two.
export function readGitMeta() {
  const raw = gitBlock("git-meta") ?? ""
  const [name = "", generatedAt = ""] = raw.split("\n").map((line) => line.trim())
  return { name: name || "repository", generatedAt }
}

// True when the status skill injected its data blocks into the page.
export function hasGitData() {
  return ["git-meta", "git-refs", "git-status", "git-worktrees", "git-log"].every(
    (id) => gitBlock(id) !== null
  )
}
