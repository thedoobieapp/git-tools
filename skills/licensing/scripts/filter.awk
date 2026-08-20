# The licences that survive a set of answers, and what is left to ask about.
# The interview turns each answer into tags, and this script does the
# surviving — so a shortlist is the catalogue's own tag lists filtered, never a
# recollection of which licence is "the permissive one with patents".
#
#   REQUIRE  every term must be on the licence, space separated
#   EXCLUDE  no term may be on it
#   SHAPE    permissive | copyleft | public-domain | other, one of the four
#            classes shape.awk computes, or empty for any
#   SPLIT    non-empty: also print, per tag, how many survivors carry it
#
# A term is a bare tag — `patent-use`, matched in whichever group carries it —
# or `group:tag`, which pins it to one: `permissions:patent-use` is the express
# grant, `limitations:patent-use` is the licence saying it grants none, and the
# two are opposites spelled with the same word. A tag matches whole: requiring
# `same-license` does not reach `same-license--file`.
#
# Every survivor prints as `<shape>  <slug> — <Title> (<SPDX-Id>)`, starred
# where choosealicense features it, featured first and alphabetical within, and
# the last line is `count=N`. `count=0` is an answer: nothing in the catalogue
# does all of that at once.
#
# With SPLIT set, a `splits:` block follows the listing, one `n/N group:tag`
# line per tag any survivor carries, in the order the tags were first seen.
# It is what says whether a question is still worth asking: a tag on `0` is an
# option nobody left offers, a tag on `N` is one they all do, and neither
# divides the survivors any further.
#
#   REQUIRE="conditions:same-license permissions:patent-use" SHAPE=copyleft \
#     find "$refs" -maxdepth 1 -name '*.txt' | sort | xargs awk -f filter.awk

BEGIN {
  want = ENVIRON["SHAPE"]
  nreq = split(ENVIRON["REQUIRE"], req, /[[:space:]]+/)
  nexc = split(ENVIRON["EXCLUDE"], exc, /[[:space:]]+/)
  split_on = (ENVIRON["SPLIT"] != "")
}

FNR == 1 {
  c = 0; grp = ""; tags = " "; cond = ""; t = ""; s = ""; f = ""
  slug = FILENAME; sub(/.*\//, "", slug); sub(/\.txt$/, "", slug)
}
/^---$/ {
  c++
  if (c == 2) consider()
  next
}
c < 2 && /^(permissions|conditions|limitations):/ { grp = $0; sub(/:.*/, "", grp); next }
c < 2 && grp != "" && /^[[:space:]]*-[[:space:]]*/ {
  tag = $0; sub(/^[[:space:]]*-[[:space:]]*/, "", tag); sub(/[[:space:]]*$/, "", tag)
  tags = tags grp ":" tag " "
  if (grp == "conditions") cond = cond " " tag
  next
}
c < 2 && /^[^[:space:]]/ { grp = "" }
c < 2 && /^title: /        { if (t == "") t = substr($0, 8) }
c < 2 && /^spdx-id: /      { if (s == "") s = substr($0, 10) }
c < 2 && /^featured: true/ { f = 1 }

function consider(   i, n, own, sh, line) {
  sh = shape(cond)
  if (want != "" && sh != want) return
  for (i = 1; i <= nreq; i++) if (req[i] != "" && !has(req[i])) return
  for (i = 1; i <= nexc; i++) if (exc[i] != "" &&  has(exc[i])) return
  line = sprintf("%s%-14s %s — %s (%s)", (f ? "* " : "  "), sh, slug, t, s)
  if (f) top[++nt] = line; else rest[++nr] = line
  if (split_on) {
    n = split(tags, own, /[[:space:]]+/)
    for (i = 1; i <= n; i++) {
      if (own[i] == "") continue
      if (!(own[i] in tally)) order[++no] = own[i]
      tally[own[i]]++
    }
  }
}

function has(term) {
  if (index(term, ":")) return index(tags, " " term " ") > 0
  return tags ~ ("[[:space:]][a-z]+:" term "[[:space:]]")
}

function shape(list) {
  if (list == "") return "public-domain"
  if (list ~ /same-license/) return "copyleft"
  if (list == " include-copyright") return "permissive"
  return "other"
}

END {
  for (i = 1; i <= nt; i++) print top[i]
  for (i = 1; i <= nr; i++) print rest[i]
  printf "count=%d\n", nt + nr
  if (split_on && no) {
    print "splits:"
    for (i = 1; i <= no; i++) printf "  %d/%d %s\n", tally[order[i]], nt + nr, order[i]
  }
}
