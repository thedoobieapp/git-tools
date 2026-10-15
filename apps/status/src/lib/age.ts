import { translate as t } from "@/lib/i18n"

const DAY = 24 * 60 * 60 * 1000

const startOfDay = (date: Date) =>
  new Date(date.getFullYear(), date.getMonth(), date.getDate()).getTime()

// Short age label: "today", "1d", "3d", "2mo", "1y". Counts calendar days, so a
// commit from yesterday evening is "1d" even when it is under 24 hours old.
export function age(date: Date | null) {
  if (!date) return "—"
  const days = Math.max(
    0,
    Math.round((startOfDay(new Date()) - startOfDay(date)) / DAY)
  )
  if (days < 1) return t("age.today")
  if (days < 30) return t("age.days", { n: days })
  if (days < 365) return t("age.months", { n: Math.min(11, Math.floor(days / 30)) })
  return t("age.years", { n: Math.floor(days / 365) })
}
