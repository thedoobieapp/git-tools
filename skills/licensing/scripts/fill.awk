# The holes `write.awk` left standing, filled in from values the user gave.
# Takes the written LICENSE, and the values through the environment — YEAR,
# FULLNAME, PROJECT, PROJECTURL, EMAIL.
#
#   YEAR=2026 FULLNAME="Ada Lovelace" awk -f fill.awk LICENSE > LICENSE.tmp
#
# It runs after the copy, over the file on disk, never over a reference: the
# catalogue is a snapshot and stays as it was fetched. What it fills is the
# list in `holders.awk` and nothing else, so cecill-2.1's `Ce[a] C[nrs]` and
# blueoak-1.0.0's `[Notices](#notices)` are licence text here as they are
# there. A token whose value is empty is left exactly as it is — declining to
# name a project is an answer, and a half-filled notice is worse than a
# visible blank.
#
# Replacement is index/substr with the value from the environment, so a holder
# named `Smith & Sons` lands literally — `&`, `\` and `/` are metacharacters to
# sed and to awk's own gsub.
#
#   4  the file was empty, so nothing was written and there is nothing to move

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

{
  b = 1
  line = $0
  for (i = 1; i <= n; i++) {
    if (val[i] == "") { left[i] += count(line, tok[i]); continue }
    done[i] += count(line, tok[i])
    line = rep(line, tok[i], val[i])
  }
  print line
}

END {
  if (!b) { warn("nothing to fill in — " FILENAME " is empty"); exit 4 }
  for (i = 1; i <= n; i++) {
    if (done[i]) warn(tok[i] " filled in, " done[i] (done[i] == 1 ? " place" : " places"))
    if (left[i]) warn(tok[i] " left standing, " left[i] (left[i] == 1 ? " place" : " places"))
  }
}

function add(t, e) { n++; tok[n] = t; env[n] = e; val[n] = ENVIRON[e] }

function count(str, from,   k, c) {
  while ((k = index(str, from)) > 0) { c++; str = substr(str, k + length(from)) }
  return c
}

function rep(str, from, to,   out, i) {
  while ((i = index(str, from)) > 0) {
    out = out substr(str, 1, i - 1) to
    str = substr(str, i + length(from))
  }
  return out str
}

function warn(msg) { print "fill: " msg > "/dev/stderr" }
