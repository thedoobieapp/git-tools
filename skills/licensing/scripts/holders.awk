# Every placeholder in one licence file, and whether its own `how:` names it.
# Takes one licence file; takes nothing from the environment.
#
#   awk -f holders.awk mit.txt
#
#   [year]                     YEAR       named    1
#   [fullname]                 FULLNAME   named    1
#
# `write.awk` fills in what `how:` names and nothing else, because a bracket
# upstream's instruction does not name is licence text. That leaves two kinds
# of hole, and this script is what tells them apart:
#
#   named    a value the write refuses to run without — get it before writing
#   unnamed  a hole the write leaves standing — apache-2.0's appendix, ncsa's
#            [projecturl], every holder in mulanpsl-2.0, whose `how:` names
#            none of the three it carries. Fill these after the write, from
#            values the user gave, with `fill.awk`
#
# A bracket is a placeholder because it is on this list, never because of its
# shape. cecill-2.1 spells its own name `Ce[a] C[nrs] I[nria] L[ogiciel]
# L[ibre]` and blueoak-1.0.0 carries the markdown link `[Notices](#notices)`;
# a pattern would offer to fill those in, and they are the licence's words.
#
#   4  the file has no frontmatter or no body

BEGIN {
  n = 0
  add("[year]",                      "YEAR")
  add("[Year]",                      "YEAR")
  add("[yyyy]",                      "YEAR")
  add("[fullname]",                  "FULLNAME")
  add("[name of copyright owner]",   "FULLNAME")
  add("[name of copyright holder]",  "FULLNAME")
  add("[project]",                   "PROJECT")
  add("[Software Name]",             "PROJECT")
  add("[projecturl]",                "PROJECTURL")
  add("[email]",                     "EMAIL")
}

/^---$/ { c++; next }

# The frontmatter's `how:`, and whatever it wraps onto — the same reading
# `write.awk` does, so the two cannot disagree about what is named.
c == 1 {
  if ($0 ~ /^how:/) { how = substr($0, 5); inh = 1; next }
  if (inh) {
    if ($0 ~ /^[[:space:]]*$/ || $0 ~ /^[a-z][a-z0-9-]*:/) inh = 0
    else how = how " " $0
  }
  next
}

c >= 2 {
  if (!b && $0 ~ /^[[:space:]]*$/) next
  b = 1
  for (i = 1; i <= n; i++) hits[i] += count($0, tok[i])
}

END {
  if (c < 2) { warn("no frontmatter in " FILENAME); exit 4 }
  if (!b)    { warn("no licence text in " FILENAME); exit 4 }
  for (i = 1; i <= n; i++) {
    named = count(how, tok[i]) > 0
    if (!hits[i] && !named) continue
    printf "%-27s %-11s %-8s %d\n", tok[i], env[i], named ? "named" : "unnamed", hits[i]
  }
}

function add(t, e) { n++; tok[n] = t; env[n] = e }

function count(str, from,   k, c2) {
  while ((k = index(str, from)) > 0) { c2++; str = substr(str, k + length(from)) }
  return c2
}

function warn(msg) { print "holders: " msg > "/dev/stderr" }
