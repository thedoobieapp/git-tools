import { XIcon } from "lucide-react"

import { Badge } from "@/components/ui/badge"
import { Button } from "@/components/ui/button"
import {
  Sidebar,
  SidebarContent,
  SidebarGroup,
  SidebarGroupContent,
  SidebarGroupLabel,
  SidebarHeader,
} from "@/components/ui/sidebar"
import { readGitLog } from "@/lib/git-log"
import { readGitRefs, readGitTags } from "@/lib/git-refs"
import { useI18n } from "@/lib/i18n"

const STATUS_COLOR: Record<string, string> = {
  A: "text-green-600",
  M: "text-yellow-600",
  D: "text-red-600",
  R: "text-blue-600",
}

function Field({ label, children }: { label: string; children: React.ReactNode }) {
  return (
    <SidebarGroup>
      <SidebarGroupLabel>{label}</SidebarGroupLabel>
      <SidebarGroupContent className="px-2 text-sm">{children}</SidebarGroupContent>
    </SidebarGroup>
  )
}

function BranchGroup({
  label,
  names,
  hidden,
  onToggle,
}: {
  label: string
  names: { name: string; current: boolean }[]
  hidden: Set<string>
  onToggle: (name: string) => void
}) {
  if (names.length === 0) return null
  return (
    <div className="mb-2">
      <div className="px-2 py-1 text-xs text-muted-foreground">{label}</div>
      <ul className="flex flex-col">
        {names.map(({ name, current }) => (
          <li key={name}>
            <label className="flex cursor-pointer items-center gap-2 rounded-md px-2 py-1 text-sm hover:bg-sidebar-accent">
              <input
                type="checkbox"
                checked={!hidden.has(name)}
                onChange={() => onToggle(name)}
              />
              <span className="min-w-0 flex-1 truncate font-mono text-xs">
                {name}
              </span>
              {current && <Badge variant="outline">HEAD</Badge>}
            </label>
          </li>
        ))}
      </ul>
    </div>
  )
}

export function GraphDetail({
  selected,
  onClose,
  hidden,
  onToggleBranch,
  onSetAllBranches,
}: {
  selected: string | null
  onClose: () => void
  hidden: Set<string>
  onToggleBranch: (name: string) => void
  onSetAllBranches: (visible: boolean) => void
}) {
  const { language, t } = useI18n()
  const commit = readGitLog().find((candidate) => candidate.hash === selected)
  const tags = new Set(readGitTags().map((tag) => tag.name))
  const branches = readGitRefs().branches
  const local = branches.filter((branch) => !branch.remote)
  const remote = branches.filter((branch) => branch.remote)

  return (
    <Sidebar side="right" collapsible="offcanvas">
      <SidebarHeader className="gap-2 border-b p-4">
        <div className="flex items-center justify-between">
          <h2 className="text-sm font-medium">{t("graph.branches")}</h2>
          <div className="flex gap-1">
            <Button variant="ghost" size="xs" onClick={() => onSetAllBranches(true)}>
              {t("graph.showAll")}
            </Button>
            <Button variant="ghost" size="xs" onClick={() => onSetAllBranches(false)}>
              {t("graph.hideAll")}
            </Button>
          </div>
        </div>
      </SidebarHeader>
      <SidebarContent>
        <SidebarGroup>
          <BranchGroup label={t("graph.local")} names={local} hidden={hidden} onToggle={onToggleBranch} />
          <BranchGroup label={t("graph.remote")} names={remote} hidden={hidden} onToggle={onToggleBranch} />
        </SidebarGroup>

        <div className="mt-2 flex items-center justify-between gap-2 border-t px-4 py-3">
          <h2 className="text-sm font-medium">{t("graph.commitDetails")}</h2>
          <Button variant="ghost" size="icon-sm" onClick={onClose}>
            <XIcon />
            <span className="sr-only">{t("graph.closeDetails")}</span>
          </Button>
        </div>
        {!commit ? (
          <p className="px-4 pb-4 text-sm text-muted-foreground">
            {t("graph.select")}
          </p>
        ) : (
          <>
            <div className="flex flex-col gap-2 px-4 pb-2">
              <p className="text-sm font-medium leading-snug">{commit.subject}</p>
              {commit.body && (
                <p className="whitespace-pre-wrap text-xs leading-relaxed text-muted-foreground">
                  {commit.body}
                </p>
              )}
            </div>
            <div className="flex flex-col gap-0.5 px-4 pb-2 text-xs text-muted-foreground">
              <span>{commit.date.toLocaleString(language)}</span>
              <span>{commit.author}</span>
            </div>
            <div className="flex items-center justify-between gap-2 px-4 pb-2">
              <code className="font-mono text-xs">{commit.hash.slice(0, 7)}</code>
              <Button
                variant="outline"
                size="xs"
                onClick={() => navigator.clipboard?.writeText(commit.hash)}
              >
                {t("graph.copy")}
              </Button>
            </div>
            <div className="mt-2 border-t">
              <Field label={t("graph.parent", { n: commit.parents.length })}>
                {commit.parents.length === 0 ? (
                  <span className="text-muted-foreground">{t("graph.rootCommit")}</span>
                ) : (
                  <div className="flex flex-wrap gap-2">
                    {commit.parents.map((parent) => (
                      <code key={parent} className="font-mono text-xs">
                        {parent.slice(0, 7)}
                      </code>
                    ))}
                  </div>
                )}
              </Field>
              <Field label={t("graph.refs")}>
                {commit.refs.length === 0 ? (
                  <span className="text-muted-foreground">{t("graph.none")}</span>
                ) : (
                  <div className="flex flex-wrap gap-1">
                    {commit.refs.map((ref) => (
                      <Badge
                        key={ref}
                        variant={tags.has(ref) ? "outline" : "secondary"}
                        className="font-mono"
                      >
                        {ref}
                      </Badge>
                    ))}
                  </div>
                )}
              </Field>
              <Field label={t("graph.files", { n: commit.files.length })}>
                {commit.files.length === 0 ? (
                  <span className="text-muted-foreground">{t("graph.none")}</span>
                ) : (
                  <ul className="flex flex-col gap-1.5">
                    {commit.files.map((file) => (
                      <li key={file.path} className="flex items-baseline gap-2">
                        <code
                          className={`w-3 shrink-0 font-mono text-xs ${STATUS_COLOR[file.status] ?? "text-muted-foreground"}`}
                        >
                          {file.status}
                        </code>
                        <code className="break-all font-mono text-xs">{file.path}</code>
                      </li>
                    ))}
                  </ul>
                )}
              </Field>
            </div>
          </>
        )}
      </SidebarContent>
    </Sidebar>
  )
}
