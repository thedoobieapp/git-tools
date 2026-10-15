"use client"

import * as React from "react"

import { SnapshotInfo } from "@/components/snapshot-info"
import { TeamSwitcher } from "@/components/team-switcher"
import {
  Sidebar,
  SidebarContent,
  SidebarFooter,
  SidebarGroup,
  SidebarMenu,
  SidebarMenuButton,
  SidebarMenuItem,
  SidebarHeader,
  SidebarRail,
} from "@/components/ui/sidebar"
import { useI18n } from "@/lib/i18n"
import { useRoute } from "@/lib/use-route"
import { LayoutDashboardIcon, GitMergeIcon, GitGraphIcon } from "lucide-react"

const teams = [
  {
    name: "git-tools:status",
    logo: <GitGraphIcon />,
    plan: "by The Doobie App",
  },
]

export function AppSidebar({ ...props }: React.ComponentProps<typeof Sidebar>) {
  const route = useRoute()
  const { t } = useI18n()
  return (
    <Sidebar collapsible="icon" {...props}>
      <SidebarHeader>
        <TeamSwitcher teams={teams} />
      </SidebarHeader>
      <SidebarContent>
        <SidebarGroup>
          <SidebarMenu>
            <SidebarMenuItem>
              <SidebarMenuButton
                tooltip={t("nav.dashboard")}
                isActive={route === "dashboard"}
                render={<a href="#/" />}
              >
                <LayoutDashboardIcon />
                <span>{t("nav.dashboard")}</span>
              </SidebarMenuButton>
            </SidebarMenuItem>
            <SidebarMenuItem>
              <SidebarMenuButton
                tooltip={t("nav.graph")}
                isActive={route === "graph"}
                render={<a href="#/graph" />}
              >
                <GitMergeIcon />
                <span>{t("nav.graph")}</span>
              </SidebarMenuButton>
            </SidebarMenuItem>
          </SidebarMenu>
        </SidebarGroup>
      </SidebarContent>
      <SidebarFooter>
        <SnapshotInfo />
      </SidebarFooter>
      <SidebarRail />
    </Sidebar>
  )
}
