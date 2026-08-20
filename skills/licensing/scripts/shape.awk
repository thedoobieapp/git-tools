# One line per licence: its shape, its slug, then its `conditions` tags, or
# `(none)`. Conditions are what a licence costs, so they are what the shape
# question sorts on, and the four shapes are computed here rather than read off
# the tag list by eye — in this order, which is the definition:
#
#   no conditions at all            -> public-domain
#   any tag holding same-license    -> copyleft       (--file and --library too)
#   include-copyright and nothing else -> permissive
#   anything else                   -> other          (the notice plus more)
#
# The order is what a grep for one tag cannot reproduce: include-copyright sits
# in thirty-odd licences and says nothing on its own, and Apache-2.0 carries it
# *and* document-changes, so it lands in `other`, not in `permissive`.
#
#   find "$refs" -maxdepth 1 -name '*.txt' | sort | xargs awk -f shape.awk

FNR == 1 {
  c = 0; inl = 0; cond = ""
  slug = FILENAME; sub(/.*\//, "", slug); sub(/\.txt$/, "", slug)
}
/^---$/ {
  c++
  if (c == 2) printf "%-14s %-20s %s\n", shape(cond), slug, (cond == "" ? "(none)" : substr(cond, 2))
  next
}
c < 2 && /^conditions:/ { inl = 1; next }
c < 2 && inl && /^[[:space:]]*-[[:space:]]*/ {
  t = $0; sub(/^[[:space:]]*-[[:space:]]*/, "", t); sub(/[[:space:]]*$/, "", t)
  cond = cond " " t; next
}
c < 2 && inl && /^[^[:space:]]/ { inl = 0 }

function shape(list) {
  if (list == "") return "public-domain"
  if (list ~ /same-license/) return "copyleft"
  if (list == " include-copyright") return "permissive"
  return "other"
}
