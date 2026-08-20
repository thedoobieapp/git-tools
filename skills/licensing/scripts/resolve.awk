# Ranked candidates for a free-text licence name. The query arrives in $Q, the
# licence files as arguments; every match prints as
#
#   <tier><TAB><slug> — <Title> (<SPDX-Id>)
#
# lowest tier first, and the last line is `count=N tier=T`, where T is the best
# tier anything reached and N is how many licences reached it. A caller branches
# on N alone — one candidate is taken, two to four are asked about, five or more
# are too many to ask about — and never has to judge what counts as a match.
#
# The tiers, lowest wins:
#
#   1  the query is the slug
#   2  the query is the SPDX id, case ignored
#   3  the query is a nickname, case ignored
#   4  the query appears inside a slug, a title or a nickname
#
# The query is lowercased and also tried with its spaces removed and with its
# spaces turned into hyphens, so `gpl v3`, `gplv3` and `gpl-v3` route alike.
#
#   Q="gpl v3" awk -f resolve.awk *.txt

BEGIN {
  q = tolower(ENVIRON["Q"])
  sub(/^[[:space:]]+/, "", q)
  sub(/[[:space:]]+$/, "", q)
  if (q != "") {
    variant(q)
    v = q; gsub(/[[:space:]]+/, "", v);  variant(v)
    v = q; gsub(/[[:space:]]+/, "-", v); variant(v)
  }
}

function variant(v) {
  if (v == "" || (v in seen)) return
  seen[v] = 1
  qv[++nq] = v
}

FNR == 1 {
  c = 0; t = ""; s = ""; nk = ""
  slug = FILENAME; sub(/.*\//, "", slug); sub(/\.txt$/, "", slug)
}
/^---$/ {
  c++
  if (c == 2) score()
  next
}
c < 2 && /^title: /    { if (t == "")  t = substr($0, 8) }
c < 2 && /^spdx-id: /  { if (s == "")  s = substr($0, 10) }
c < 2 && /^nickname: / { if (nk == "") nk = substr($0, 11) }

function score(   i, v, ls, lt, ln, tier, best) {
  ls = tolower(slug); lt = tolower(t); ln = tolower(nk)
  best = 0
  for (i = 1; i <= nq; i++) {
    v = qv[i]
    tier = 0
    if (v == ls) tier = 1
    else if (v == tolower(s)) tier = 2
    else if (ln != "" && v == ln) tier = 3
    else if (index(ls, v) || index(lt, v) || (ln != "" && index(ln, v))) tier = 4
    if (tier && (best == 0 || tier < best)) best = tier
  }
  if (best) {
    n++
    rt[n] = best
    rl[n] = slug " — " t " (" s ")"
  }
}

END {
  best = 0; cnt = 0
  for (tier = 1; tier <= 4; tier++)
    for (i = 1; i <= n; i++)
      if (rt[i] == tier) {
        if (best == 0) { best = tier }
        if (tier == best) cnt++
        printf "%d\t%s\n", tier, rl[i]
      }
  printf "count=%d tier=%d\n", cnt, best
}
