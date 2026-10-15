import { useSyncExternalStore } from "react"

export type Route = "dashboard" | "graph"

// Hash routes keep the single-file build working: the page is opened from disk
// and there is no server to answer /graph.
function read(): Route {
  return location.hash.replace(/^#\/?/, "") === "graph" ? "graph" : "dashboard"
}

function subscribe(callback: () => void) {
  window.addEventListener("hashchange", callback)
  return () => window.removeEventListener("hashchange", callback)
}

export function useRoute() {
  return useSyncExternalStore(subscribe, read)
}
