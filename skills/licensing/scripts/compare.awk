# Two to four licences side by side. Takes `rules.yml` first and the licence
# files after it, in the order they should appear as columns, and prints one
# markdown block per group — conditions, then permissions, then limitations —
# holding every tag that appears in at least one of them, and nothing else.
#
#   awk -f compare.awk rules.yml mit.txt gpl-3.0.txt
#
# Rows keep rules.yml's own order, which is the canonical one and the only one
# POSIX awk can hold without sorting. A cell is `yes` or `—`. After the tables,
# one `DIFFERS: <group> — <row>` line per row whose licences disagree — those rows are the
# answer, and the agreeing ones stay in the table so nothing looks left out.

FILENAME ~ /rules\.yml$/ {
  if ($0 ~ /^[a-z][a-z0-9-]*:[[:space:]]*$/) { sec = $0; sub(/:.*/, "", sec); next }
  if ($0 ~ /^-?[[:space:]]*label:[[:space:]]/) { l = $0; sub(/^-?[[:space:]]*label:[[:space:]]*/, "", l); next }
  if ($0 ~ /^-?[[:space:]]*tag:[[:space:]]/) {
    g = $0; sub(/^-?[[:space:]]*tag:[[:space:]]*/, "", g); sub(/[[:space:]]*$/, "", g)
    label[sec, g] = l; l = ""
    if (!((sec, g) in seen)) { seen[sec, g] = 1; ord[++nord] = sec SUBSEP g; osec[nord] = sec; otag[nord] = g }
    next
  }
  next
}

FNR == 1 {
  c = 0; key = ""; k++
  col[k] = FILENAME; sub(/.*\//, "", col[k]); sub(/\.txt$/, "", col[k])
}
/^---$/ { c++; next }
c != 1  { next }
/^[a-z][a-z0-9-]*:/ {
  key = $0; sub(/:.*/, "", key)
  if (key == "spdx-id") { v = $0; sub(/^spdx-id:[[:space:]]*/, "", v); if (v != "") col[k] = v }
  next
}
/^[[:space:]]*-[[:space:]]*/ {
  if (key == "permissions" || key == "conditions" || key == "limitations") {
    t = $0; sub(/^[[:space:]]*-[[:space:]]*/, "", t); sub(/[[:space:]]*$/, "", t)
    has[k, key, t] = 1
    # A tag rules.yml never defined still gets a row, at the end of its group
    # and labelled with the raw slug — a missing dictionary loses the wording,
    # never a row.
    if (!((key, t) in seen)) { seen[key, t] = 1; ord[++nord] = key SUBSEP t; osec[nord] = key; otag[nord] = t }
  }
  next
}
/^[[:space:]]*$/ { key = "" }

END {
  group("conditions", "Conditions")
  group("permissions", "Permissions")
  group("limitations", "Limitations")
  print ""
  if (nd == 0) print "DIFFERS: (none)"
  for (i = 1; i <= nd; i++) print "DIFFERS: " differs[i]
}

function group(sec, head,   i, j, row, any, first, same, cell, name) {
  print ""
  row = "| " head " |"
  for (j = 1; j <= k; j++) row = row " " col[j] " |"
  print row
  row = "|---|"
  for (j = 1; j <= k; j++) row = row "---|"
  print row
  for (i = 1; i <= nord; i++) {
    if (osec[i] != sec) continue
    any = 0
    for (j = 1; j <= k; j++) if ((j, sec, otag[i]) in has) any = 1
    if (!any) continue
    name = ((sec, otag[i]) in label) ? label[sec, otag[i]] : otag[i]
    row = "| " name " |"
    same = 1; first = ""
    for (j = 1; j <= k; j++) {
      cell = ((j, sec, otag[i]) in has) ? "yes" : "—"
      if (j == 1) first = cell; else if (cell != first) same = 0
      row = row " " cell " |"
    }
    print row
    if (!same) differs[++nd] = head " — " name
  }
}
