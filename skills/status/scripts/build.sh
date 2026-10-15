#!/usr/bin/env bash
# Gathers the repository's git data and writes the status page.
#
# Run from anywhere inside a repo. Writes two files into .claude/git-tools/:
#   status.html     a copy of references/template.html (the prebuilt page)
#   status-data.js  the git data, loaded by the page as window.__GIT_DATA__
# Read-only on the repo apart from adding `.claude/git-tools/` to .gitignore
# when nothing already ignores the output.
set -u

here=$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)
tpl="$here/../references/template.html"
[ -f "$tpl" ] || { echo "error: template not found: $tpl" >&2; exit 1; }

top=$(git rev-parse --show-toplevel 2>/dev/null) || { echo "error: not inside a git repository" >&2; exit 1; }
cd "$top" || exit 1
dir=".claude/git-tools"
page="$dir/status.html"
data="$dir/status-data.js"

# Escapes stdin for use inside a JavaScript template literal.
lit() { sed -e 's/\\/\\\\/g' -e 's/`/\\`/g' -e 's/\${/\\${/g'; }

added=no
if ! git check-ignore -q "$page"; then
  [ -s .gitignore ] && [ -n "$(tail -c1 .gitignore)" ] && echo >> .gitignore
  echo '.claude/git-tools/' >> .gitignore
  added=yes
fi

mkdir -p "$dir"
cp "$tpl" "$page"
{
  printf 'window.__GIT_DATA__ = {\n'
  printf '"git-meta": `'
  printf '%s\n%s' "$(basename "$top")" "$(date -u +%Y-%m-%dT%H:%M:%SZ)" | lit
  printf '`,\n"git-refs": `'
  git for-each-ref --format='%(refname)%1f%(refname:short)%1f%(objectname)%1f%(*objectname)%1f%(upstream:short)%1f%(upstream:track)%1f%(HEAD)' refs/heads refs/remotes refs/tags | lit
  printf '`,\n"git-status": `'
  git status --porcelain=v2 --branch | lit
  printf '`,\n"git-worktrees": `'
  git worktree list --porcelain 2>/dev/null | lit
  printf '`,\n"git-log": `'
  git log --branches --remotes --tags HEAD --topo-order --name-status --format='%x1e%H%x1f%P%x1f%an%x1f%ae%x1f%aI%x1f%D%x1f%s%x1f%b%x1f' 2>/dev/null | lit
  printf '`\n};\n'
} > "$data"

echo "page: $top/$page"
echo "data: $top/$data"
echo "gitignore entry added: $added"
echo "commits: $(git log --branches --remotes --tags HEAD --format=%H 2>/dev/null | wc -l | tr -d ' ')"
