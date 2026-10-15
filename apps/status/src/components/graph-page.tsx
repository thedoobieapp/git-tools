import { useMemo } from "react"

import { Badge } from "@/components/ui/badge"
import { age } from "@/lib/age"
import { layoutGraph, type GraphRow } from "@/lib/git-graph"
import { readGitLog } from "@/lib/git-log"
import { readGitRefs, readGitTags } from "@/lib/git-refs"
import { useI18n } from "@/lib/i18n"

const ROW = 32
const LANE = 14
const COLORS = [
  "#00B8FF",
  "#FF3D81",
  "#7CFF4F",
  "#FFD400",
  "#B05CFF",
  "#FF8A00",
  "#00F5C4",
  "#FF5252",
]
const laneColor = (lane: number) => COLORS[lane % COLORS.length]

function GraphLanes({ row, width }: { row: GraphRow; width: number }) {
  const x = (lane: number) => lane * LANE + LANE / 2
  const mid = ROW / 2
  const color = laneColor
  const lines: React.ReactNode[] = []

  row.before.forEach((hash, lane) => {
    if (!hash) return
    if (hash === row.commit.hash) {
      lines.push(
        <line key={`in${lane}`} x1={x(lane)} y1={0} x2={x(row.column)} y2={mid} stroke={color(lane)} strokeWidth={2} />
      )
    } else {
      lines.push(
        <line key={`pass${lane}`} x1={x(lane)} y1={0} x2={x(lane)} y2={ROW} stroke={color(lane)} strokeWidth={2} />
      )
    }
  })
  row.parentColumns.forEach((lane, index) => {
    lines.push(
      <line key={`out${index}`} x1={x(row.column)} y1={mid} x2={x(lane)} y2={ROW} stroke={color(lane)} strokeWidth={2} />
    )
  })

  const merge = row.commit.parents.length > 1
  return (
    <svg width={width * LANE} height={ROW} className="shrink-0" aria-hidden>
      {lines}
      <circle
        cx={x(row.column)}
        cy={mid}
        r={merge ? 5 : 4}
        fill={merge ? "var(--background)" : color(row.column)}
        stroke={color(row.column)}
        strokeWidth={2}
      />
    </svg>
  )
}

export function GraphPage({
  selected,
  onSelect,
  hidden,
}: {
  selected: string | null
  onSelect: (hash: string) => void
  hidden: Set<string>
}) {
  const { t } = useI18n()
  const { rows, width } = useMemo(() => {
    const log = readGitLog()
    const byHash = new Map(log.map((commit) => [commit.hash, commit]))
    // A commit is shown when a branch that is not hidden can reach it.
    const seen = new Set<string>()
    const stack = readGitRefs()
      .branches.filter((branch) => !hidden.has(branch.name))
      .map((branch) => branch.oid)
    while (stack.length) {
      const hash = stack.pop()!
      if (seen.has(hash)) continue
      seen.add(hash)
      byHash.get(hash)?.parents.forEach((parent) => stack.push(parent))
    }
    return layoutGraph(log.filter((commit) => seen.has(commit.hash)))
  }, [hidden])
  const tags = useMemo(() => new Set(readGitTags().map((tag) => tag.name)), [])

  return (
    <div className="flex min-h-0 flex-1 flex-col rounded-xl border">
      {rows.length === 0 ? (
        <p className="p-6 text-sm text-muted-foreground">{t("graph.noCommits")}</p>
      ) : (
        <ul className="flex-1 overflow-auto">
          {rows.map((row) => {
            const { commit } = row
            return (
              <li key={commit.hash}>
                <button
                  type="button"
                  onClick={() => onSelect(commit.hash)}
                  aria-pressed={selected === commit.hash}
                  className={`flex w-full items-center gap-3 px-3 text-left text-sm hover:bg-muted/50 ${
                    selected === commit.hash ? "bg-muted" : ""
                  }`}
                  style={{ height: ROW }}
                >
                  <GraphLanes row={row} width={width} />
                  {commit.refs.slice(0, 3).map((ref) => (
                    <Badge
                      key={ref}
                      variant="outline"
                      className="font-mono"
                      style={{
                        color: laneColor(row.column),
                        borderColor: laneColor(row.column),
                        backgroundColor: tags.has(ref)
                          ? undefined
                          : `color-mix(in srgb, ${laneColor(row.column)} 20%, transparent)`,
                      }}
                    >
                      {ref}
                    </Badge>
                  ))}
                  <span className="min-w-0 flex-1 truncate">{commit.subject}</span>
                  <code className="font-mono text-xs text-muted-foreground">
                    {commit.hash.slice(0, 7)}
                  </code>
                  <span className="w-12 text-right text-xs text-muted-foreground">
                    {age(commit.date)}
                  </span>
                </button>
              </li>
            )
          })}
        </ul>
      )}
    </div>
  )
}
