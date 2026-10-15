import { useState } from "react"
import { PanelLeftIcon, PanelRightIcon } from "lucide-react"

import { AppSidebar } from "@/components/app-sidebar"
import { ActivityHeatmap } from "@/components/activity-heatmap"
import { BranchHealth } from "@/components/branch-health"
import { GraphDetail } from "@/components/graph-detail"
import { GraphPage } from "@/components/graph-page"
import { RecentCommits } from "@/components/recent-commits"
import { Tags } from "@/components/tags"
import { Worktrees } from "@/components/worktrees"
import { YouAreHere } from "@/components/you-are-here"
import {
  Breadcrumb,
  BreadcrumbItem,
  BreadcrumbLink,
  BreadcrumbList,
  BreadcrumbPage,
  BreadcrumbSeparator,
} from "@/components/ui/breadcrumb"
import { Button } from "@/components/ui/button"
import { Separator } from "@/components/ui/separator"
import {
  SidebarInset,
  SidebarProvider,
  useSidebar,
} from "@/components/ui/sidebar"
import { TooltipProvider } from "@/components/ui/tooltip"
import { hasGitData, readGitMeta } from "@/lib/git-meta"
import { readGitRefs } from "@/lib/git-refs"
import { useI18n } from "@/lib/i18n"
import { useRoute } from "@/lib/use-route"

const repo = readGitMeta()

function Dashboard() {
  return (
    <div className="flex flex-1 flex-col gap-4 p-4 pt-0">
      <YouAreHere />
      <div className="grid gap-4 md:grid-cols-2">
        <RecentCommits />
        <ActivityHeatmap />
        <Worktrees />
        <BranchHealth />
        <Tags />
      </div>
    </div>
  )
}

// Reads the nearest provider, which on the graph page is the right sidebar's.
function DetailTrigger() {
  const { t } = useI18n()
  const { toggleSidebar } = useSidebar()
  return (
    <Button
      variant="ghost"
      size="icon-sm"
      onClick={toggleSidebar}
      className="ml-auto"
    >
      <PanelRightIcon />
      <span className="sr-only">{t("app.toggleDetails")}</span>
    </Button>
  )
}

function Shell() {
  const route = useRoute()
  const { t } = useI18n()
  const left = useSidebar()
  const [selected, setSelected] = useState<string | null>(null)
  const [detailOpen, setDetailOpen] = useState(false)
  const [hidden, setHidden] = useState<Set<string>>(() => new Set())
  const graph = route === "graph"

  const page = (
    <SidebarInset>
      <header className="sticky top-0 z-10 flex h-16 shrink-0 bg-background items-center gap-2 px-4 transition-[width,height] ease-linear group-has-data-[collapsible=icon]/sidebar-wrapper:h-12">
        <Button
          variant="ghost"
          size="icon-sm"
          className="-ml-1"
          onClick={left.toggleSidebar}
        >
          <PanelLeftIcon />
          <span className="sr-only">{t("app.toggleSidebar")}</span>
        </Button>
        <Separator
          orientation="vertical"
          className="mr-2 data-vertical:h-4 data-vertical:self-auto"
        />
        <Breadcrumb>
          <BreadcrumbList>
            <BreadcrumbItem className="hidden md:block">
              <BreadcrumbLink href="#/">{repo.name}</BreadcrumbLink>
            </BreadcrumbItem>
            <BreadcrumbSeparator className="hidden md:block" />
            <BreadcrumbItem>
              <BreadcrumbPage>{graph ? t("nav.graph") : t("nav.dashboard")}</BreadcrumbPage>
            </BreadcrumbItem>
          </BreadcrumbList>
        </Breadcrumb>
        {graph && <DetailTrigger />}
      </header>
      {graph ? (
        <div className="flex min-h-0 flex-1 flex-col p-4 pt-0">
          <GraphPage
            selected={selected}
            hidden={hidden}
            onSelect={(hash) => {
              setSelected(hash)
              setDetailOpen(true)
            }}
          />
        </div>
      ) : (
        <Dashboard />
      )}
    </SidebarInset>
  )

  return (
    <>
      <AppSidebar />
      {graph ? (
        <SidebarProvider
          secondary
          open={detailOpen}
          onOpenChange={setDetailOpen}
          className="min-h-0 flex-1"
        >
          {page}
          <GraphDetail
            selected={selected}
            onClose={() => setSelected(null)}
            hidden={hidden}
            onToggleBranch={(name) =>
              setHidden((current) => {
                const next = new Set(current)
                if (!next.delete(name)) next.add(name)
                return next
              })
            }
            onSetAllBranches={(visible) =>
              setHidden(
                visible
                  ? new Set()
                  : new Set(readGitRefs().branches.map((branch) => branch.name))
              )
            }
          />
        </SidebarProvider>
      ) : (
        page
      )}
    </>
  )
}

function NoData() {
  const { t } = useI18n()
  return (
    <div className="flex min-h-svh items-center justify-center p-6">
      <div className="max-w-md text-center">
        <h1 className="text-lg font-medium">{t("noData.title")}</h1>
        <p className="mt-2 text-sm text-muted-foreground">
          {t("noData.before")} <code>git-tools:status</code>{" "}
          {t("noData.after")}
        </p>
      </div>
    </div>
  )
}

export default function App() {
  if (!hasGitData()) return <NoData />
  return (
    <TooltipProvider>
      <SidebarProvider>
        <Shell />
      </SidebarProvider>
    </TooltipProvider>
  )
}
