import { readGitMeta } from "@/lib/git-meta"
import { useI18n } from "@/lib/i18n"

function snapshotLabel(iso: string, locale: string) {
  const date = new Date(iso)
  if (Number.isNaN(date.getTime())) return null
  return date.toLocaleString(locale, {
    dateStyle: "medium",
    timeStyle: "short",
  })
}

export function SnapshotInfo() {
  const { language, t } = useI18n()
  const snapshot = snapshotLabel(readGitMeta().generatedAt, language)

  return (
    <p className="px-2 text-xs text-muted-foreground group-data-[collapsible=icon]:hidden">
      {snapshot ? t("snapshot.taken", { date: snapshot }) : t("snapshot.plain")}{" "}
      {t("snapshot.runBefore")} <code>git-tools:status</code>{" "}
      {t("snapshot.runAfter")}
    </p>
  )
}
