# One line per licence: slug, title, SPDX id, nickname, and a star on the three
# choosealicense features. Reads the frontmatter only — the c<2 guard stops
# every field at the closing fence, so licence text can never reach the output.
#
#   find "$refs" -maxdepth 1 -name '*.txt' | sort | xargs awk -f index.awk

FNR == 1 {
  c = 0; t = ""; s = ""; n = ""; f = ""
  slug = FILENAME; sub(/.*\//, "", slug); sub(/\.txt$/, "", slug)
}
/^---$/ {
  c++
  if (c == 2) printf "%s%s — %s (%s)%s\n", (f ? "* " : "  "), slug, t, s, (n ? "  [" n "]" : "")
  next
}
c < 2 && /^title: /        { if (t == "") t = substr($0, 8) }
c < 2 && /^spdx-id: /      { if (s == "") s = substr($0, 10) }
c < 2 && /^nickname: /     { if (n == "") n = substr($0, 11) }
c < 2 && /^featured: true/ { f = 1 }
