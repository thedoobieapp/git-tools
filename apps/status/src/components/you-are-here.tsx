import { ArrowRightIcon, GitBranchIcon } from "lucide-react"

import { Badge } from "@/components/ui/badge"
import { Card, CardContent } from "@/components/ui/card"
import { readGitStatus } from "@/lib/git-status"
import { useI18n } from "@/lib/i18n"

export function YouAreHere() {
  const { t } = useI18n()
  const status = readGitStatus()

  const changes = [
    status.conflicts && t("here.conflicted", { n: status.conflicts }),
    status.staged && t("here.staged", { n: status.staged }),
    status.unstaged && t("here.unstaged", { n: status.unstaged }),
    status.untracked && t("here.untracked", { n: status.untracked }),
  ].filter(Boolean)

  return (
    <Card size="sm">
      <CardContent>
        <div className="flex flex-wrap items-center gap-x-3 gap-y-2">
          <span className="text-xs text-muted-foreground">{t("here.title")}</span>
          <Badge variant="secondary" className="gap-1 font-mono">
            <GitBranchIcon />
            {status.branch ?? t("here.detached", { oid: status.oid?.slice(0, 7) ?? "?" })}
          </Badge>
          {status.upstream ? (
            <>
              <ArrowRightIcon className="size-3.5 text-muted-foreground" />
              <span className="font-mono text-sm">{status.upstream}</span>
              <span className="text-sm text-muted-foreground">
                ↑{status.ahead} ↓{status.behind}
              </span>
            </>
          ) : (
            <span className="text-sm text-muted-foreground">{t("here.noUpstream")}</span>
          )}
          <span className="text-sm">
            {changes.length ? changes.join(" · ") : t("here.clean")}
          </span>
        </div>
      </CardContent>
    </Card>
  )
}
