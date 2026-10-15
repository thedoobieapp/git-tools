// The status skill writes the repository's git output next to the page as
// status-data.js, which sets window.__GIT_DATA__ (block id -> raw text). The dev
// server instead embeds the same blocks as <script type="text/plain"> elements.
declare global {
  interface Window {
    __GIT_DATA__?: Record<string, string>
  }
}

export function gitBlock(id: string): string | null {
  return (
    window.__GIT_DATA__?.[id] ?? document.getElementById(id)?.textContent ?? null
  )
}
