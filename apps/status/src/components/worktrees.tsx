import { Badge } from "@/components/ui/badge"
import { Card, CardContent, CardHeader, CardTitle } from "@/components/ui/card"
import { age } from "@/lib/age"
import { readGitLog } from "@/lib/git-log"
import { makeComparer, readGitRefs } from "@/lib/git-refs"
import { readGitWorktrees } from "@/lib/git-worktrees"
import { useI18n } from "@/lib/i18n"

export function Worktrees() {
  const { t } = useI18n()
  const worktrees = readGitWorktrees()
  const commits = readGitLog()
  const { branches, remoteHeadOid } = readGitRefs()
  const { compare } = makeComparer(branches, remoteHeadOid, commits)
  const byHash = new Map(commits.map((commit) => [commit.hash, commit]))

  return (
    <Card size="sm">
      <CardHeader>
        <CardTitle>{t("worktrees.title")}</CardTitle>
        <p className="text-xs text-muted-foreground">
          {t("worktrees.summary", { n: worktrees.length })}
        </p>
      </CardHeader>
      <CardContent>
        {worktrees.length === 0 ? (
          <p className="text-sm text-muted-foreground">{t("worktrees.none")}</p>
        ) : (
          <ul className="flex flex-col">
            {worktrees.map((worktree) => {
              const commit = worktree.oid ? byHash.get(worktree.oid) : undefined
              const { ahead, behind } = worktree.oid
                ? compare(worktree.oid)
                : { ahead: 0, behind: 0 }
              return (
                <li
                  key={worktree.path}
                  className="flex justify-between gap-3 border-t py-2 first:border-t-0"
                >
                  <div className="flex min-w-0 flex-col gap-0.5">
                    <div className="flex min-w-0 items-center gap-2">
                      <span className="truncate font-mono text-xs">
                        {worktree.path}
                      </span>
                      {worktree.branch && (
                        <Badge className="shrink-0">{worktree.branch}</Badge>
                      )}
                      {worktree.detached && (
                        <Badge variant="outline" className="shrink-0">
                          {t("worktrees.detached")}
                        </Badge>
                      )}
                    </div>
                    <span className="truncate text-xs text-muted-foreground">
                      {commit?.subject ?? "—"}
                    </span>
                  </div>
                  <div className="flex shrink-0 flex-col items-end gap-0.5">
                    <div className="flex items-center gap-1.5">
                      {worktree.main && <Badge variant="secondary">{t("worktrees.main")}</Badge>}
                      {worktree.bare && <Badge variant="secondary">{t("worktrees.bare")}</Badge>}
                      {worktree.locked && <Badge variant="outline">{t("worktrees.locked")}</Badge>}
                      {worktree.prunable && (
                        <Badge variant="destructive">{t("worktrees.prunable")}</Badge>
                      )}
                      <span className="text-xs whitespace-nowrap text-muted-foreground">
                        ↑{ahead} ↓{behind} · {age(commit?.date ?? null)}
                      </span>
                    </div>
                    <code className="font-mono text-xs text-muted-foreground">
                      {worktree.oid?.slice(0, 7) ?? "—"}
                    </code>
                  </div>
                </li>
              )
            })}
          </ul>
        )}
      </CardContent>
    </Card>
  )
}
