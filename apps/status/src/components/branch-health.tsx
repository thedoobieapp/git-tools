import { Badge } from "@/components/ui/badge"
import { Card, CardContent, CardHeader, CardTitle } from "@/components/ui/card"
import { age } from "@/lib/age"
import { readGitLog } from "@/lib/git-log"
import {
  computeBranchHealth,
  readGitRefs,
  STALE_DAYS,
  type BranchHealth as Health,
} from "@/lib/git-refs"
import { useI18n } from "@/lib/i18n"

function Counter({ value, label }: { value: number; label: string }) {
  return (
    <div className="rounded-lg bg-muted/50 px-2 py-1.5">
      <div className="text-lg leading-tight font-medium">{value}</div>
      <div className="text-xs text-muted-foreground">{label}</div>
    </div>
  )
}

function Row({ branch }: { branch: Health }) {
  const { t } = useI18n()
  return (
    <li className="flex items-center gap-2 border-t py-1.5 text-sm first:border-t-0">
      <span
        className={`min-w-0 truncate font-mono text-xs ${
          branch.remote ? "text-muted-foreground" : ""
        }`}
      >
        {branch.name}
      </span>
      {branch.current && <Badge>{t("badge.current")}</Badge>}
      {branch.isDefault && <Badge variant="secondary">{t("badge.default")}</Badge>}
      {branch.remote && <Badge variant="outline">{t("badge.remote")}</Badge>}
      {branch.merged && <Badge variant="secondary">{t("badge.merged")}</Badge>}
      {branch.stale && <Badge variant="outline">{t("badge.stale")}</Badge>}
      {branch.gone && <Badge variant="destructive">{t("badge.upstreamGone")}</Badge>}
      {!branch.remote && !branch.isDefault && !branch.upstream && (
        <Badge variant="destructive">{t("badge.noUpstream")}</Badge>
      )}
      <span className="ml-auto whitespace-nowrap text-xs text-muted-foreground">
        {branch.isDefault ? t("badge.default") : `↑${branch.ahead} ↓${branch.behind}`}
        {" · "}
        {age(branch.date)}
      </span>
    </li>
  )
}

export function BranchHealth() {
  const { t } = useI18n()
  const { branches, remoteHeadOid } = readGitRefs()
  const health = computeBranchHealth(branches, remoteHeadOid, readGitLog())

  const rows = [...health].sort(
    (a, b) =>
      Number(a.remote) - Number(b.remote) ||
      Number(b.current) - Number(a.current) ||
      Number(b.isDefault) - Number(a.isDefault) ||
      (b.date?.getTime() ?? 0) - (a.date?.getTime() ?? 0)
  )

  return (
    <Card size="sm">
      <CardHeader>
        <CardTitle>{t("branches.title")}</CardTitle>
        <p className="text-xs text-muted-foreground">
          {t("branches.help", { days: STALE_DAYS })}
        </p>
      </CardHeader>
      <CardContent className="flex flex-col gap-3">
        <div className="grid grid-cols-5 gap-2">
          <Counter value={health.filter((b) => !b.remote).length} label={t("branches.local")} />
          <Counter value={health.filter((b) => b.remote).length} label={t("branches.remote")} />
          <Counter value={health.filter((b) => b.merged).length} label={t("branches.merged")} />
          <Counter value={health.filter((b) => b.stale).length} label={t("branches.stale")} />
          <Counter value={health.filter((b) => b.unpushed).length} label={t("branches.unpushed")} />
        </div>
        {rows.length === 0 ? (
          <p className="text-sm text-muted-foreground">{t("branches.none")}</p>
        ) : (
          <ul className="flex max-h-64 flex-col overflow-y-auto">
            {rows.map((branch) => (
              <Row key={`${branch.remote}:${branch.name}`} branch={branch} />
            ))}
          </ul>
        )}
      </CardContent>
    </Card>
  )
}
