import { useSyncExternalStore } from "react"

export type Language = "en" | "pt-BR"

export const LANGUAGES: { value: Language; label: string }[] = [
  { value: "en", label: "English" },
  { value: "pt-BR", label: "Português (Brasil)" },
]

const en = {
  "nav.dashboard": "Dashboard",
  "nav.graph": "Graph",
  "app.toggleSidebar": "Toggle sidebar",
  "app.toggleDetails": "Toggle details",
  "noData.title": "No repository data",
  "noData.before": "This page has no git snapshot embedded in it. Run the",
  "noData.after": "skill inside a repository to generate one.",
  "snapshot.taken": "Snapshot taken {date}.",
  "snapshot.plain": "Snapshot.",
  "snapshot.runBefore": "Run",
  "snapshot.runAfter": "again to refresh.",
  "menu.language": "Language",
  "menu.theme": "Theme",
  "theme.light": "Light",
  "theme.dark": "Dark",
  "here.title": "You are here",
  "here.detached": "detached at {oid}",
  "here.noUpstream": "no upstream",
  "here.clean": "Working tree clean",
  "here.conflicted": "{n} conflicted",
  "here.staged": "{n} staged",
  "here.unstaged": "{n} unstaged",
  "here.untracked": "{n} untracked",
  "commits.title": "Recent commits",
  "commits.none": "No commits yet.",
  "commits.merge": "merge",
  "activity.title": "Activity",
  "activity.commits_one": "{n} commit",
  "activity.commits_other": "{n} commits",
  "activity.days_one": "{n} active day in the last year",
  "activity.days_other": "{n} active days in the last year",
  "activity.cell_one": "{n} commit on {date}",
  "activity.cell_other": "{n} commits on {date}",
  "activity.less": "Less",
  "activity.more": "More",
  "branches.title": "Branches and health",
  "branches.help":
    "Stale means no commit in {days} days. Ahead and behind are measured against the default branch.",
  "branches.local": "Local",
  "branches.remote": "Remote",
  "branches.merged": "Merged",
  "branches.stale": "Stale",
  "branches.unpushed": "Unpushed",
  "branches.none": "No branches yet.",
  "badge.current": "current",
  "badge.default": "default",
  "badge.remote": "remote",
  "badge.merged": "merged",
  "badge.stale": "stale",
  "badge.upstreamGone": "upstream gone",
  "badge.noUpstream": "no upstream",
  "tags.title": "Tags",
  "tags.summary": "{total} in total.",
  "tags.summaryLimited": "{total} in total, showing the latest {count}.",
  "tags.none": "No tags yet.",
  "tags.latest": "latest",
  "worktrees.title": "Worktrees",
  "worktrees.summary_one":
    "{n} checked out. Ahead and behind are measured against the default branch.",
  "worktrees.summary_other":
    "{n} checked out. Ahead and behind are measured against the default branch.",
  "worktrees.none": "No worktrees.",
  "worktrees.detached": "detached",
  "worktrees.main": "main",
  "worktrees.bare": "bare",
  "worktrees.locked": "locked",
  "worktrees.prunable": "prunable",
  "graph.noCommits": "No commits to show. Check a branch in the right sidebar.",
  "graph.branches": "Branches",
  "graph.showAll": "Show all",
  "graph.hideAll": "Hide all",
  "graph.local": "Local",
  "graph.remote": "Remote",
  "graph.commitDetails": "Commit details",
  "graph.closeDetails": "Close commit details",
  "graph.select": "Select a commit to see its details.",
  "graph.copy": "Copy",
  "graph.parent_one": "Parent",
  "graph.parent_other": "Parents",
  "graph.rootCommit": "None (root commit)",
  "graph.refs": "Refs",
  "graph.none": "None",
  "graph.files": "Changed files ({n})",
  "age.today": "today",
  "age.days": "{n}d",
  "age.months": "{n}mo",
  "age.years": "{n}y",
} as const

type Dictionary = Record<keyof typeof en, string>

const ptBR: Dictionary = {
  "nav.dashboard": "Painel",
  "nav.graph": "Grafo",
  "app.toggleSidebar": "Alternar barra lateral",
  "app.toggleDetails": "Alternar detalhes",
  "noData.title": "Sem dados do repositório",
  "noData.before":
    "Esta página não tem um snapshot do git embutido. Execute a skill",
  "noData.after": "dentro de um repositório para gerar um.",
  "snapshot.taken": "Snapshot gerado em {date}.",
  "snapshot.plain": "Snapshot.",
  "snapshot.runBefore": "Execute",
  "snapshot.runAfter": "novamente para atualizar.",
  "menu.language": "Idioma",
  "menu.theme": "Tema",
  "theme.light": "Claro",
  "theme.dark": "Escuro",
  "here.title": "Você está aqui",
  "here.detached": "desanexado em {oid}",
  "here.noUpstream": "sem upstream",
  "here.clean": "Árvore de trabalho limpa",
  "here.conflicted": "{n} em conflito",
  "here.staged": "{n} preparados",
  "here.unstaged": "{n} não preparados",
  "here.untracked": "{n} não rastreados",
  "commits.title": "Commits recentes",
  "commits.none": "Nenhum commit ainda.",
  "commits.merge": "merge",
  "activity.title": "Atividade",
  "activity.commits_one": "{n} commit",
  "activity.commits_other": "{n} commits",
  "activity.days_one": "{n} dia ativo no último ano",
  "activity.days_other": "{n} dias ativos no último ano",
  "activity.cell_one": "{n} commit em {date}",
  "activity.cell_other": "{n} commits em {date}",
  "activity.less": "Menos",
  "activity.more": "Mais",
  "branches.title": "Branches e saúde",
  "branches.help":
    "Obsoleta significa sem commits há {days} dias. À frente e atrás são medidos em relação à branch padrão.",
  "branches.local": "Locais",
  "branches.remote": "Remotas",
  "branches.merged": "Mescladas",
  "branches.stale": "Obsoletas",
  "branches.unpushed": "Não enviadas",
  "branches.none": "Nenhuma branch ainda.",
  "badge.current": "atual",
  "badge.default": "padrão",
  "badge.remote": "remota",
  "badge.merged": "mesclada",
  "badge.stale": "obsoleta",
  "badge.upstreamGone": "upstream removido",
  "badge.noUpstream": "sem upstream",
  "tags.title": "Tags",
  "tags.summary": "{total} no total.",
  "tags.summaryLimited": "{total} no total, mostrando as {count} mais recentes.",
  "tags.none": "Nenhuma tag ainda.",
  "tags.latest": "mais recente",
  "worktrees.title": "Worktrees",
  "worktrees.summary_one":
    "{n} em checkout. À frente e atrás são medidos em relação à branch padrão.",
  "worktrees.summary_other":
    "{n} em checkout. À frente e atrás são medidos em relação à branch padrão.",
  "worktrees.none": "Nenhuma worktree.",
  "worktrees.detached": "desanexada",
  "worktrees.main": "principal",
  "worktrees.bare": "bare",
  "worktrees.locked": "bloqueada",
  "worktrees.prunable": "removível",
  "graph.noCommits":
    "Nenhum commit para mostrar. Marque uma branch na barra lateral direita.",
  "graph.branches": "Branches",
  "graph.showAll": "Mostrar todas",
  "graph.hideAll": "Ocultar todas",
  "graph.local": "Locais",
  "graph.remote": "Remotas",
  "graph.commitDetails": "Detalhes do commit",
  "graph.closeDetails": "Fechar detalhes do commit",
  "graph.select": "Selecione um commit para ver os detalhes.",
  "graph.copy": "Copiar",
  "graph.parent_one": "Pai",
  "graph.parent_other": "Pais",
  "graph.rootCommit": "Nenhum (commit raiz)",
  "graph.refs": "Referências",
  "graph.none": "Nenhuma",
  "graph.files": "Arquivos alterados ({n})",
  "age.today": "hoje",
  "age.days": "{n}d",
  "age.months": "{n}m",
  "age.years": "{n}a",
}

const dictionaries: Record<Language, Dictionary> = { en, "pt-BR": ptBR }

type BaseKey<K> = K extends `${infer B}_${"one" | "other"}` ? B : K
export type MessageKey = BaseKey<keyof typeof en>
export type Translate = (
  key: MessageKey,
  vars?: Record<string, string | number>
) => string

const STORAGE_KEY = "git-tools-status-language"
const listeners = new Set<() => void>()

function initial(): Language {
  try {
    const saved = localStorage.getItem(STORAGE_KEY)
    if (saved === "en" || saved === "pt-BR") return saved
  } catch {
    // storage can be blocked for file:// pages
  }
  return navigator.language.toLowerCase().startsWith("pt") ? "pt-BR" : "en"
}

let current: Language = initial()
document.documentElement.lang = current

export const getLanguage = () => current

export function setLanguage(next: Language) {
  if (next === current) return
  current = next
  document.documentElement.lang = next
  try {
    localStorage.setItem(STORAGE_KEY, next)
  } catch {
    // keep the choice for this visit only
  }
  listeners.forEach((listener) => listener())
}

function subscribe(listener: () => void) {
  listeners.add(listener)
  return () => listeners.delete(listener)
}

export function makeTranslate(language: Language): Translate {
  const dictionary = dictionaries[language] as Record<string, string>
  const rules = new Intl.PluralRules(language)
  return (key, vars = {}) => {
    let template = dictionary[key]
    if (template === undefined) {
      const rule = rules.select(Number(vars.n)) === "one" ? "one" : "other"
      template = dictionary[`${key}_${rule}`] ?? key
    }
    return template.replace(/\{(\w+)\}/g, (_, name) => String(vars[name] ?? ""))
  }
}

// For plain helpers; components must call `useI18n` so they re-render on change.
export const translate: Translate = (key, vars) =>
  makeTranslate(current)(key, vars)

export function useI18n() {
  const language = useSyncExternalStore(subscribe, getLanguage)
  return { language, t: makeTranslate(language), setLanguage }
}
