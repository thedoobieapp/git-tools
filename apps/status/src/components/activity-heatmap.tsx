import { Card, CardContent, CardHeader, CardTitle } from "@/components/ui/card"
import { readGitLog } from "@/lib/git-log"
import { useI18n } from "@/lib/i18n"

const WEEKS = 53

// Short month and weekday names for the page language, without pt-BR's dots.
function names(locale: string, options: Intl.DateTimeFormatOptions, count: number, base: (i: number) => Date) {
  const format = new Intl.DateTimeFormat(locale, options)
  return Array.from({ length: count }, (_, i) => format.format(base(i)).replace(/\.$/, ""))
}

const pad = (n: number) => String(n).padStart(2, "0")
const key = (d: Date) => `${d.getFullYear()}-${pad(d.getMonth() + 1)}-${pad(d.getDate())}`

// Fill for intensity 0..4: the preset's primary mixed into the muted surface.
function levelColor(level: number) {
  if (level === 0) return "var(--muted)"
  return `color-mix(in oklab, var(--primary) ${level * 25}%, var(--muted))`
}

export function ActivityHeatmap() {
  const { language, t } = useI18n()
  const MONTHS = names(language, { month: "short" }, 12, (i) => new Date(2023, i, 1))
  // 2023-01-01 is a Sunday; only Mon, Wed and Fri get a label.
  const weekdays = names(language, { weekday: "short" }, 7, (i) => new Date(2023, 0, 1 + i))
  const DAY_LABELS = weekdays.map((label, i) => (i % 2 === 1 ? label : ""))
  // Count commits per calendar day, using the date the author recorded.
  const counts = new Map<string, number>()
  for (const commit of readGitLog()) {
    const day = key(commit.date)
    counts.set(day, (counts.get(day) ?? 0) + 1)
  }

  // Sunday-first grid ending with the current week.
  const today = new Date()
  today.setHours(0, 0, 0, 0)
  const start = new Date(today)
  start.setDate(today.getDate() - today.getDay() - (WEEKS - 1) * 7)

  const weeks = Array.from({ length: WEEKS }, (_, w) =>
    Array.from({ length: 7 }, (_, d) => {
      const date = new Date(start)
      date.setDate(start.getDate() + w * 7 + d)
      return date
    })
  )

  let total = 0
  let activeDays = 0
  let max = 0
  for (const week of weeks) {
    for (const date of week) {
      if (date > today) continue
      const n = counts.get(key(date)) ?? 0
      total += n
      if (n) activeDays++
      max = Math.max(max, n)
    }
  }

  const monthLabels = weeks.map((week, w) => {
    const month = week[0].getMonth()
    return w === 0 || month !== weeks[w - 1][0].getMonth() ? MONTHS[month] : ""
  })

  return (
    <Card size="sm">
      <CardHeader>
        <CardTitle>{t("activity.title")}</CardTitle>
        <p className="text-xs text-muted-foreground">
          {t("activity.commits", { n: total })} · {t("activity.days", { n: activeDays })}
        </p>
      </CardHeader>
      <CardContent className="overflow-x-auto">
        <div className="flex min-w-[420px] gap-2">
          <div className="grid grid-rows-[auto_repeat(7,1fr)] gap-0.5 text-[10px] text-muted-foreground">
            <span />
            {DAY_LABELS.map((label, i) => (
              <span key={i} className="flex items-center">
                {label}
              </span>
            ))}
          </div>
          <div className="flex-1">
            <div
              className="mb-1 grid gap-0.5 text-[10px] text-muted-foreground"
              style={{ gridTemplateColumns: `repeat(${WEEKS}, minmax(0, 1fr))` }}
            >
              {monthLabels.map((label, w) => (
                <span key={w} className="overflow-visible whitespace-nowrap">
                  {label}
                </span>
              ))}
            </div>
            <div
              className="grid grid-flow-col grid-rows-7 gap-0.5"
              style={{ gridTemplateColumns: `repeat(${WEEKS}, minmax(0, 1fr))` }}
            >
              {weeks.flat().map((date) => {
                const future = date > today
                const n = counts.get(key(date)) ?? 0
                const level = n === 0 ? 0 : Math.max(1, Math.ceil((n / max) * 4))
                return (
                  <div
                    key={key(date)}
                    title={t("activity.cell", { n, date: date.toLocaleDateString(language, { dateStyle: "medium" }) })}
                    className="aspect-square rounded-[2px]"
                    style={{
                      background: future ? "transparent" : levelColor(level),
                    }}
                  />
                )
              })}
            </div>
            <div className="mt-2 flex items-center justify-end gap-1 text-[10px] text-muted-foreground">
              {t("activity.less")}
              {[0, 1, 2, 3, 4].map((level) => (
                <span
                  key={level}
                  className="size-2.5 rounded-[2px]"
                  style={{ background: levelColor(level) }}
                />
              ))}
              {t("activity.more")}
            </div>
          </div>
        </div>
      </CardContent>
    </Card>
  )
}
