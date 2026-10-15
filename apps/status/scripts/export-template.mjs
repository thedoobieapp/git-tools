// Copies dist/index.html to the status skill as its template. The page loads its
// data from status-data.js, written next to it by the skill's build script.
import { mkdirSync, readFileSync, writeFileSync } from 'node:fs'
import { dirname, resolve } from 'node:path'
import { fileURLToPath } from 'node:url'

const root = resolve(dirname(fileURLToPath(import.meta.url)), '..')
const out = resolve(root, '../../skills/status/references/template.html')
const html = readFileSync(resolve(root, 'dist/index.html'), 'utf8')
const template = html

if (!html.includes('status-data.js')) throw new Error('dist/index.html does not load status-data.js')
mkdirSync(dirname(out), { recursive: true })
writeFileSync(out, template)
console.log(`template: ${out} (${template.length} bytes)`)
