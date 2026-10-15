import { execFileSync } from 'node:child_process'
import path from 'node:path'
import tailwindcss from '@tailwindcss/vite'
import react from '@vitejs/plugin-react'
import { defineConfig, loadEnv, type Plugin } from 'vite'
import { viteSingleFile } from 'vite-plugin-singlefile'

// `STATUS_REPO=/path/to/repo pnpm dev` (or STATUS_REPO in .env.local) embeds that
// repository's git data the same way the status skill does, so the page can be
// developed against a real history. Dev server only; builds are untouched.
function repoData(repo: string | undefined): Plugin {
  
  return {
    name: 'status-repo-data',
    apply: 'serve',
    transformIndexHtml() {
      if (!repo) return
      const dir = path.resolve(repo.replace(/^~(?=$|\/)/, process.env.HOME ?? '~'))
      const git = (...args: string[]) =>
        execFileSync('git', args, { cwd: dir, encoding: 'utf8', maxBuffer: 512 * 1024 * 1024 })
      const block = (id: string, text: string) => ({
        tag: 'script',
        attrs: { type: 'text/plain', id },
        children: text.replace(/<\//g, '<\\/'),
        injectTo: 'body' as const,
      })
      const scope = ['--branches', '--remotes', '--tags', 'HEAD']
      const top = git('rev-parse', '--show-toplevel').trim()
      return [
        block('git-meta', `${path.basename(top)}\n${new Date().toISOString()}`),
        block(
          'git-refs',
          git('for-each-ref', '--format=%(refname)%1f%(refname:short)%1f%(objectname)%1f%(*objectname)%1f%(upstream:short)%1f%(upstream:track)%1f%(HEAD)', 'refs/heads', 'refs/remotes', 'refs/tags')
        ),
        block('git-status', git('status', '--porcelain=v2', '--branch')),
        block('git-worktrees', git('worktree', 'list', '--porcelain')),
        block(
          'git-log',
          git('log', ...scope, '--topo-order', '--name-status', '--format=%x1e%H%x1f%P%x1f%an%x1f%ae%x1f%aI%x1f%D%x1f%s%x1f%b%x1f')
        ),
      ]
    },
  }
}

// https://vite.dev/config/
export default defineConfig(({ mode }) => {
  const env = loadEnv(mode, import.meta.dirname, 'STATUS_')
  return {
    plugins: [react(), tailwindcss(), viteSingleFile(), repoData(process.env.STATUS_REPO || env.STATUS_REPO)],
    resolve: {
      alias: { '@': path.resolve(import.meta.dirname, './src') },
    },
  }
})
