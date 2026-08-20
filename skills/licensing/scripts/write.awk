# The licence body, ready to land in a LICENSE file. Takes one licence file, and
# the values through the environment — YEAR, FULLNAME, PROJECT, EMAIL.
#
#   YEAR=2026 FULLNAME="Ada Lovelace" awk -f write.awk mit.txt > LICENSE.tmp
#
# What gets substituted is decided by the licence's own `how:` field, upstream's
# instruction for this licence and the complete list: a bracket `how:` does not
# name is licence text and is left alone. Apache-2.0 and GPL-3.0 name nothing,
# so the `[yyyy]` in their appendix — a notice for your *source* files, not for
# this one — survives untouched; ncsa names [year] [fullname] [project] and its
# [projecturl] stays; vim names [project] alone, so no year is wanted and none
# missing.
#
# Nothing is written on a value that is not there. A `how:` naming [fullname]
# with FULLNAME unset exits 2 having printed no body, so the caller's
# `awk … > tmp && mv tmp LICENSE` leaves the target as it was. Exit codes:
#
#   2  a placeholder `how:` names has no value in the environment
#   3  a named placeholder survived into the output
#   4  the file has no frontmatter or no body, or `how:` names an unknown one
#
# Replacement is index/substr with the value from the environment, so a holder
# named `Smith & Sons` lands literally — `&`, `\` and `/` are metacharacters to
# sed and to awk's own gsub.

BEGIN {
  order[1] = "year"; order[2] = "fullname"; order[3] = "project"; order[4] = "email"
  vals["year"]     = ENVIRON["YEAR"]
  vals["fullname"] = ENVIRON["FULLNAME"]
  vals["project"]  = ENVIRON["PROJECT"]
  vals["email"]    = ENVIRON["EMAIL"]
}

/^---$/ {
  c++
  if (c == 2) settle()
  next
}

# The frontmatter: `how:` and whatever it wraps onto, up to the next top-level
# key or the blank line after it. Every file holds it on one line today; a
# refreshed snapshot that wraps must not silently drop a placeholder.
c == 1 {
  if ($0 ~ /^how:/) { how = substr($0, 5); inh = 1; next }
  if (inh) {
    if ($0 ~ /^[[:space:]]*$/ || $0 ~ /^[a-z][a-z0-9-]*:/) inh = 0
    else how = how " " $0
  }
  next
}

# The body: the `c >= 2` guard drops the frontmatter and both fences, `!b` drops
# the blank lines under the closing fence and nothing after them.
c >= 2 {
  if (!b && $0 ~ /^[[:space:]]*$/) next
  b = 1
  line = $0
  for (i = 1; i <= nn; i++) line = rep(line, "[" need[i] "]", vals[need[i]])
  for (i = 1; i <= nn; i++) if (index(line, "[" need[i] "]")) left = 1
  print line
}

END {
  if (err) exit err
  if (c < 2) { warn("no frontmatter in " FILENAME); exit 4 }
  if (!b)    { warn("no licence text in " FILENAME); exit 4 }
  if (left)  { warn("a placeholder survived into the output"); exit 3 }
}

# At the closing fence: work out what `how:` asks for, and refuse before a
# single body line is printed if anything asked for is not there.
function settle(   i, t, miss) {
  scan(how)
  if (err) exit err
  for (i = 1; i <= 4; i++) {
    t = order[i]
    if (want[t] && vals[t] == "") { warn("missing value for [" t "]"); miss = 1 }
  }
  if (miss) { err = 2; exit err }
  for (i = 1; i <= 4; i++) if (want[order[i]]) need[++nn] = order[i]
}

# Every [token] in `how:`. One outside the four is a licence this script does
# not know how to fill in — a hard failure, never a quiet skip.
function scan(txt,   i, j, tok) {
  while ((i = index(txt, "[")) > 0) {
    txt = substr(txt, i + 1)
    j = index(txt, "]")
    if (j == 0) return
    tok = substr(txt, 1, j - 1)
    txt = substr(txt, j + 1)
    if (tok in vals) want[tok] = 1
    else { warn("unknown placeholder [" tok "] in how:"); err = 4 }
  }
}

function rep(str, from, to,   out, i) {
  while ((i = index(str, from)) > 0) {
    out = out substr(str, 1, i - 1) to
    str = substr(str, i + length(from))
  }
  return out str
}

function warn(msg) { print "write: " msg > "/dev/stderr" }
