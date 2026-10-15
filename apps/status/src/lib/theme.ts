import { useSyncExternalStore } from "react"

export type Theme = "light" | "dark"

const STORAGE_KEY = "git-tools-status-theme"
const listeners = new Set<() => void>()

// The page ships with the dark class on <html>, so dark is the default.
function initial(): Theme {
  try {
    const saved = localStorage.getItem(STORAGE_KEY)
    if (saved === "light" || saved === "dark") return saved
  } catch {
    // storage can be blocked for file:// pages
  }
  return "dark"
}

let current: Theme = initial()
document.documentElement.classList.toggle("dark", current === "dark")

export function setTheme(next: Theme) {
  if (next === current) return
  current = next
  document.documentElement.classList.toggle("dark", next === "dark")
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

export function useTheme() {
  const theme = useSyncExternalStore(subscribe, () => current)
  return { theme, setTheme }
}
