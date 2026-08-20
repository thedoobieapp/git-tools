#!/usr/bin/env bash
#
# Refresh skills/licensing/references/ from choosealicense.com.
#
# Resolves gh-pages to a commit, downloads that tree as one tarball, verifies
# the archive end to end, stages the licences outside the plugin, and only then
# swaps them in. Any failure leaves references/ exactly as it was.
#
# Usage: bash refresh-references.sh [--keep-backup]
#
#   --keep-backup   rename the outgoing references/ to references-<timestamp>/
#                   instead of discarding it. Off by default: this directory is
#                   version-controlled, so `git checkout -- references` already
#                   restores it, and a copy in the tree ships to every install.

set -eu

repo="github/choosealicense.com"
branch="gh-pages"

skill=$(cd "$(dirname "$0")/.." && pwd)
live="$skill/references"
old="$skill/.references.outgoing"
keep_backup=""

case "${1:-}" in
  --keep-backup) keep_backup=1 ;;
  "") ;;
  *) echo "usage: $(basename "$0") [--keep-backup]" >&2; exit 2 ;;
esac

die() { printf 'refresh: %s\nreferences/ is untouched.\n' "$*" >&2; exit 1; }

# A kill -9 mid-swap leaves references/ gone and the outgoing copy holding it.
[ -d "$old" ] && [ ! -d "$live" ] && mv "$old" "$live" || true

tmp=$(mktemp -d "${TMPDIR:-/tmp}/licensing-refs.XXXXXX")
cleanup() {
  if [ -d "$old" ] && [ ! -d "$live" ]; then mv "$old" "$live"; fi
  rm -rf "$tmp" "$old"
}
trap cleanup EXIT
trap 'exit 130' INT TERM

# --- resolve the commit ----------------------------------------------------
sha=$(git ls-remote "https://github.com/$repo" "refs/heads/$branch" 2>/dev/null | awk '{print $1; exit}') || true
case "$sha" in
  [0-9a-f][0-9a-f][0-9a-f][0-9a-f][0-9a-f][0-9a-f][0-9a-f][0-9a-f][0-9a-f][0-9a-f][0-9a-f][0-9a-f][0-9a-f][0-9a-f][0-9a-f][0-9a-f][0-9a-f][0-9a-f][0-9a-f][0-9a-f][0-9a-f][0-9a-f][0-9a-f][0-9a-f][0-9a-f][0-9a-f][0-9a-f][0-9a-f][0-9a-f][0-9a-f][0-9a-f][0-9a-f][0-9a-f][0-9a-f][0-9a-f][0-9a-f][0-9a-f][0-9a-f][0-9a-f][0-9a-f]) ;;
  *) die "could not resolve $repo@$branch to a commit — check the network." ;;
esac

have=$(grep -o '[0-9a-f]\{40\}' "$live/SOURCE.md" 2>/dev/null | head -1) || true
whole=$(ls "$live" 2>/dev/null | grep -c '\.txt$') || true
if [ "${have:-none}" = "$sha" ] && [ "${whole:-0}" -ge 40 ]; then
  echo "Already at ${sha%"${sha#???????}"}… — $whole licences on disk. Nothing fetched."
  exit 0
fi

# --- fetch and verify the archive ------------------------------------------
echo "Fetching $repo@$branch ($(echo "$sha" | cut -c1-7)) …"
curl -fsSL "https://codeload.github.com/$repo/tar.gz/$sha" -o "$tmp/src.tgz" \
  || die "the download failed — check the network."

# gzip -t decompresses the whole stream and checks its CRC32 and length
# trailer. tar alone cannot do this job: extracting a subset stops reading
# before the trailer, so a corrupted archive still exits 0 and still yields the
# expected file count and byte total, with licence text silently altered.
gzip -t "$tmp/src.tgz" 2>/dev/null \
  || die "the archive failed its integrity check — a truncated or corrupted download."

mkdir -p "$tmp/stage" "$tmp/new"
tar -xzf "$tmp/src.tgz" -C "$tmp/stage" --strip-components=1 \
    "*/_licenses" "*/_data/rules.yml" "*/LICENSE.md" 2>/dev/null \
  || die "the archive does not carry _licenses/, _data/rules.yml and LICENSE.md."

cp "$tmp/stage/_licenses/"*.txt "$tmp/new/"
cp "$tmp/stage/_data/rules.yml" "$tmp/new/rules.yml"
# Upstream is MIT, which asks that its notice travel with substantial portions.
cp "$tmp/stage/LICENSE.md" "$tmp/new/UPSTREAM-LICENSE"

count=$(ls "$tmp/new" | grep -c '\.txt$') || true
[ "${count:-0}" -ge 40 ] || die "only ${count:-0} licences staged, expected 40 or more."
[ -s "$tmp/new/rules.yml" ] || die "rules.yml is missing or empty."
[ -s "$tmp/new/UPSTREAM-LICENSE" ] || die "upstream's own LICENSE.md is missing — it ships with the snapshot."

# --- provenance ------------------------------------------------------------
cat > "$tmp/new/SOURCE.md" <<EOF
# Where this came from

|  |  |
|---|---|
| Upstream | https://github.com/$repo |
| Branch | \`$branch\` |
| Commit | \`$sha\` |
| Paths | \`_licenses/\` and \`_data/rules.yml\` |
| Fetched | $(date -u +%Y-%m-%dT%H:%M:%SZ) |
| Licences | $count |

A verbatim snapshot of another project, replaced wholesale by the next run of
\`skills/licensing/scripts/refresh-references.sh\`.

choosealicense.com is published by GitHub, Inc. and contributors under the MIT
licence, whose full text travels with this snapshot as \`UPSTREAM-LICENSE\`. The
licence texts are the verbatim originals; \`rules.yml\` is the tag dictionary
describing what each licence permits, requires and limits.
EOF

# --- swap ------------------------------------------------------------------
if [ -d "$live" ]; then mv "$live" "$old"; fi
mv "$tmp/new" "$live"

if [ -n "$keep_backup" ] && [ -d "$old" ]; then
  backup="$skill/references-$(date +%Y-%m-%d-%H-%M-%S)"
  mv "$old" "$backup"
  echo "Previous references kept at $(basename "$backup")/"
fi

echo "$count licences + rules.yml -> skills/licensing/references/"
echo "Upstream commit $sha"
echo "Review with: git diff --stat -- skills/licensing/references"
