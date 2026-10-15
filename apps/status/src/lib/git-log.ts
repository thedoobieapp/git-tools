import { gitBlock } from "@/lib/git-data"
// Parses the `git log` block the skill embeds as
// <script type="text/plain" id="git-log">. Records start with \x1e and carry
// hash, parents, author name, author email, ISO date, refs, subject and body
// separated by \x1f; the --name-status lines that follow are the changed files.
export type GitFile = {
  status: string
  path: string
}

export type GitCommit = {
  hash: string
  parents: string[]
  author: string
  date: Date
  refs: string[]
  subject: string
  body: string
  files: GitFile[]
}

export function readGitLog(): GitCommit[] {
  const raw = gitBlock("git-log") ?? ""
  return raw
    .replace(/<\\\//g, "</")
    .split("\x1e")
    .slice(1)
    .map((record) => {
      const [hash, parents, author, , date, refs, subject, body = "", changes = ""] =
        record.split("\x1f")
      return {
        hash,
        parents: parents.split(" ").filter(Boolean),
        author,
        date: new Date(date),
        refs: refs
          .split(", ")
          .map((ref) => ref.replace(/^HEAD -> /, "").replace(/^tag: /, ""))
          .filter((ref) => ref && ref !== "HEAD"),
        subject,
        body: body.trim(),
        files: changes
          .split("\n")
          .filter((line) => line.includes("\t"))
          .map((line) => {
            const [status, ...paths] = line.split("\t")
            return { status: status[0], path: paths.join(" → ") }
          }),
      }
    })
}

// Commits reachable from `head`, in the log's own (topological) order.
export function reachableFrom(commits: GitCommit[], head: string | null) {
  const byHash = new Map(commits.map((commit) => [commit.hash, commit]))
  if (!head || !byHash.has(head)) return commits

  const seen = new Set<string>()
  const stack = [head]
  while (stack.length) {
    const hash = stack.pop()!
    if (seen.has(hash)) continue
    seen.add(hash)
    byHash.get(hash)?.parents.forEach((parent) => stack.push(parent))
  }
  return commits.filter((commit) => seen.has(commit.hash))
}
