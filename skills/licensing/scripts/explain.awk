# One licence, every field expanded, in the order a report reads them. Takes
# `rules.yml` first and one licence file second; every tag comes back as
# `Label — the sentence rules.yml gives it`, so no tag can be reported as a bare
# slug and none can be dropped for brevity — the script emits all of them.
#
#   awk -f explain.awk rules.yml mit.txt
#
# A tag rules.yml does not define is printed raw and said to be undefined,
# because inventing a definition for a slug is worse than printing it. Labels
# are keyed by section as well as tag: `patent-use` is a permission and a
# limitation, with opposite meanings.

FILENAME ~ /rules\.yml$/ {
  if ($0 ~ /^[a-z][a-z0-9-]*:[[:space:]]*$/) { sec = $0; sub(/:.*/, "", sec); next }
  if ($0 ~ /^-?[[:space:]]*description:[[:space:]]/) { d = $0; sub(/^-?[[:space:]]*description:[[:space:]]*/, "", d); next }
  if ($0 ~ /^-?[[:space:]]*label:[[:space:]]/)       { l = $0; sub(/^-?[[:space:]]*label:[[:space:]]*/, "", l); next }
  if ($0 ~ /^-?[[:space:]]*tag:[[:space:]]/) {
    g = $0; sub(/^-?[[:space:]]*tag:[[:space:]]*/, "", g); sub(/[[:space:]]*$/, "", g)
    label[sec, g] = l; desc[sec, g] = d
    d = ""; l = ""
    next
  }
  next
}

FNR == 1 { c = 0; key = "" }
/^---$/  { c++; next }
c != 1   { next }

# A top-level key: everything after the colon is the value, and `[]` is empty.
/^[a-z][a-z0-9-]*:/ {
  key = $0; sub(/:.*/, "", key)
  v = $0; sub(/^[a-z][a-z0-9-]*:[[:space:]]*/, "", v)
  if (v == "[]") v = ""
  if (v != "") f[key] = v
  next
}
# A list item under permissions / conditions / limitations.
/^[[:space:]]*-[[:space:]]*/ {
  if (key == "permissions" || key == "conditions" || key == "limitations") {
    t = $0; sub(/^[[:space:]]*-[[:space:]]*/, "", t); sub(/[[:space:]]*$/, "", t)
    tags[key, ++cnt[key]] = t
  }
  next
}
# An indented line: a `using:` entry, or a scalar wrapped onto a second line.
/^[[:space:]]+[^[:space:]]/ {
  t = $0; sub(/^[[:space:]]+/, "", t); sub(/[[:space:]]*$/, "", t)
  if (key == "using") use[++nuse] = t
  else if (key != "") f[key] = (f[key] == "" ? t : f[key] " " t)
  next
}
/^[[:space:]]*$/ { key = "" }

END {
  scalar("title"); scalar("spdx-id"); scalar("nickname")
  print ""
  scalar("description")
  section("conditions"); section("permissions"); section("limitations")
  print ""
  scalar("how")
  scalar("note")
  print ""
  print "using:"
  if (nuse == 0) print "  (none)"
  for (i = 1; i <= nuse; i++) print "  " use[i]
}

function scalar(k) { printf "%s: %s\n", k, (f[k] == "" ? "(none)" : f[k]) }

function section(k,   i, t) {
  print ""
  print k ":"
  if (cnt[k] == 0) { print "  (none)"; return }
  for (i = 1; i <= cnt[k]; i++) {
    t = tags[k, i]
    if ((k, t) in label) printf "  %s — %s\n", label[k, t], desc[k, t]
    else printf "  %s — (not defined in rules.yml)\n", t
  }
}
