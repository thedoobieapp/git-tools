import { Badge } from "@/components/ui/badge"
import { Card, CardContent, CardHeader, CardTitle } from "@/components/ui/card"
import { age } from "@/lib/age"
import { readGitLog } from "@/lib/git-log"
import { readGitTags } from "@/lib/git-refs"
import { useI18n } from "@/lib/i18n"

const COUNT = 5

export function Tags() {
  const { t } = useI18n()
  const byHash = new Map(readGitLog().map((commit) => [commit.hash, commit]))
  const tags = readGitTags()
    .map((tag) => ({ ...tag, date: byHash.get(tag.oid)?.date ?? null }))
    .sort((a, b) => (b.date?.getTime() ?? 0) - (a.date?.getTime() ?? 0))

  return (
    <Card size="sm">
      <CardHeader>
        <CardTitle>{t("tags.title")}</CardTitle>
        <p className="text-xs text-muted-foreground">
          {tags.length > COUNT
            ? t("tags.summaryLimited", { total: tags.length, count: COUNT })
            : t("tags.summary", { total: tags.length })}
        </p>
      </CardHeader>
      <CardContent>
        {tags.length === 0 ? (
          <p className="text-sm text-muted-foreground">{t("tags.none")}</p>
        ) : (
          <ul className="flex flex-col">
            {tags.slice(0, COUNT).map((tag, index) => (
              <li
                key={tag.name}
                className="flex items-center gap-2 border-t py-1.5 text-sm first:border-t-0"
              >
                <span className="font-mono text-xs">{tag.name}</span>
                {index === 0 && <Badge variant="secondary">{t("tags.latest")}</Badge>}
                <code className="ml-auto font-mono text-xs text-muted-foreground">
                  {tag.oid.slice(0, 7)}
                </code>
                <span className="w-10 text-right text-xs whitespace-nowrap text-muted-foreground">
                  {age(tag.date)}
                </span>
              </li>
            ))}
          </ul>
        )}
      </CardContent>
    </Card>
  )
}
