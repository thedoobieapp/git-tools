import { Badge } from "@/components/ui/badge"
import { Card, CardContent, CardHeader, CardTitle } from "@/components/ui/card"
import { readGitLog, reachableFrom } from "@/lib/git-log"
import { readGitStatus } from "@/lib/git-status"
import { useI18n } from "@/lib/i18n"

const COUNT = 5
const UNITS: [Intl.RelativeTimeFormatUnit, number][] = [
  ["year", 365 * 24 * 3600],
  ["month", 30 * 24 * 3600],
  ["week", 7 * 24 * 3600],
  ["day", 24 * 3600],
  ["hour", 3600],
  ["minute", 60],
]

function relative(date: Date, locale: string) {
  const seconds = (date.getTime() - Date.now()) / 1000
  const format = new Intl.RelativeTimeFormat(locale, { numeric: "auto" })
  for (const [unit, size] of UNITS) {
    if (Math.abs(seconds) >= size) {
      return format.format(Math.round(seconds / size), unit)
    }
  }
  return format.format(0, "second")
}

export function RecentCommits() {
  const { language, t } = useI18n()
  const { oid } = readGitStatus()
  const commits = reachableFrom(readGitLog(), oid).slice(0, COUNT)

  return (
    <Card size="sm">
      <CardHeader>
        <CardTitle>{t("commits.title")}</CardTitle>
      </CardHeader>
      <CardContent>
        {commits.length === 0 ? (
          <p className="text-sm text-muted-foreground">{t("commits.none")}</p>
        ) : (
          <ul className="flex flex-col">
            {commits.map((commit) => (
              <li
                key={commit.hash}
                className="flex items-center gap-2 border-t py-1.5 text-sm first:border-t-0"
              >
                <code className="font-mono text-xs text-muted-foreground">
                  {commit.hash.slice(0, 7)}
                </code>
                <span className="min-w-0 flex-1 truncate">{commit.subject}</span>
                {commit.parents.length > 1 && (
                  <Badge variant="outline">{t("commits.merge")}</Badge>
                )}
                {commit.refs.slice(0, 2).map((ref) => (
                  <Badge key={ref} variant="secondary" className="font-mono">
                    {ref}
                  </Badge>
                ))}
                <span className="whitespace-nowrap text-xs text-muted-foreground">
                  {relative(commit.date, language)}
                </span>
              </li>
            ))}
          </ul>
        )}
      </CardContent>
    </Card>
  )
}
