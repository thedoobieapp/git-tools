# Flag the candidate paths that usually should not be committed.
#
# Reads repo-relative paths on stdin, one per line, and prints one line per
# path that matches a category of ../references/gitignore-patterns.md:
#
#   <category><TAB><path><TAB><what matched>
#
# A path that matches nothing prints nothing, so no output at all means the
# working set is clean. The match is a heuristic, exactly as the catalogue
# says — a committed vendor/ in Go and a checked-in .env.example are both
# ordinary — so every line is a warning for the user to rule on, never a
# decision this script gets to make on its own.
#
# A path is reported once, under the first category it matches, in the
# catalogue's own order: secrets first, because that is the one that cannot be
# undone by a later commit.
#
#   { git diff --cached --name-only; git ls-files --others --exclude-standard; } \
#     | sort -u | awk -f screen.awk
#
# MAXBYTES overrides the large-file threshold, which is 5 MB by default. Size
# is read with wc, so a staged deletion — a path git names but the working
# tree no longer holds — measures 0 and is never flagged as large.

function base(p) { sub(/.*\//, "", p); return p }

# Whether re matches a whole path component: "logs" hits logs/x and a/logs/x,
# and misses logs.txt or catalogs/x. re is a regex, so dots arrive escaped.
function dir(p, re) { return p ~ ("(^|/)" re "(/|$)") }

# The path as a shell word, so a space or a quote in it cannot end the command.
function shq(s) { gsub(/'/, "'\\''", s); return "'" s "'" }

# wc is given the path as an argument rather than on a redirect: a redirect
# onto a path that is not there fails in the shell, which prints its own
# complaint that no 2>/dev/null of ours can reach.
function bytes(p,   cmd, line, f) {
  cmd = "wc -c " shq(p) " 2>/dev/null"
  line = ""
  cmd | getline line
  close(cmd)
  split(line, f, " ")
  return f[1] + 0
}

BEGIN {
  max = (ENVIRON["MAXBYTES"] != "") ? ENVIRON["MAXBYTES"] + 0 : 5000000
  FS = "\n"
}

{
  p = $0
  if (p == "") next
  b = base(p)
  cat = ""; why = ""

  # Secrets and credentials. Committing one means rotating it even after it is
  # removed, since it stays in history.
  if ((b == ".env" || b ~ /^\.env\./) && b !~ /^\.env\.(example|sample|template|dist)$/) {
    cat = "secrets"; why = ".env / .env.*"
  } else if (b ~ /\.(pem|key|p12|pfx|keystore|jks)$/) {
    cat = "secrets"; why = "a key or certificate store"
  } else if (b ~ /^id_(rsa|dsa|ecdsa|ed25519)$/) {
    cat = "secrets"; why = "an SSH private key"
  } else if (b == "credentials.json" || b ~ /^secrets\./ || b == ".netrc" || b == ".npmrc") {
    cat = "secrets"; why = "a credentials file"
  } else if (dir(p, "\\.aws") && b == "credentials") {
    cat = "secrets"; why = ".aws/credentials"

  # Dependencies, regenerated from a manifest.
  } else if (dir(p, "node_modules")) {
    cat = "dependencies"; why = "node_modules/"
  } else if (dir(p, "vendor")) {
    cat = "dependencies"; why = "vendor/ — committed on purpose in some Go and PHP projects"
  } else if (dir(p, "\\.venv") || dir(p, "venv") || dir(p, "env") || dir(p, "__pycache__")) {
    cat = "dependencies"; why = "a Python environment or cache directory"
  } else if (p ~ /(^|\/)[^\/]+\.egg-info(\/|$)/) {
    cat = "dependencies"; why = "*.egg-info/"
  } else if (dir(p, "\\.bundle") || dir(p, "Pods")) {
    cat = "dependencies"; why = "a Bundler or CocoaPods directory"

  # Build output and compiled artifacts.
  } else if (dir(p, "dist") || dir(p, "build") || dir(p, "out") || dir(p, "target") || dir(p, "bin") || dir(p, "obj")) {
    cat = "build output"; why = "a build directory"
  } else if (dir(p, "\\.next") || dir(p, "\\.nuxt") || dir(p, "\\.svelte-kit") || dir(p, "\\.parcel-cache")) {
    cat = "build output"; why = "a framework build directory"
  } else if (b ~ /\.(o|a|so|dll|exe|class|pyc|pyo)$/) {
    cat = "build output"; why = "a compiled artifact"

  # OS and editor cruft.
  } else if (b == ".DS_Store" || b == ".AppleDouble" || b == "Thumbs.db" || b == "Desktop.ini") {
    cat = "OS cruft"; why = "an OS metadata file"
  } else if (dir(p, "\\.idea") || dir(p, "\\.vscode")) {
    cat = "editor files"; why = "editor settings — sometimes committed on purpose"
  } else if (b ~ /\.sw[op]$/ || b ~ /~$/ || b ~ /^\.#/) {
    cat = "editor files"; why = "an editor swap or backup file"

  # Logs, caches and temporaries.
  } else if (b ~ /\.log$/ || dir(p, "logs")) {
    cat = "logs"; why = "a log file or directory"
  } else if (dir(p, "\\.cache") || dir(p, "tmp") || dir(p, "temp") || dir(p, "\\.tmp")) {
    cat = "caches"; why = "a cache or temp directory"
  } else if (dir(p, "coverage") || dir(p, "\\.nyc_output") || dir(p, "\\.pytest_cache") || dir(p, "\\.mypy_cache")) {
    cat = "caches"; why = "a test or type-check cache"

  # Large and binary blobs.
  } else if (b ~ /\.(zip|tar|tgz|gz|bz2|xz|rar|7z|iso)$/) {
    cat = "blobs"; why = "an archive"
  } else if (b ~ /\.(mp4|mov|avi|mkv|wav|psd|ai|sketch)$/) {
    cat = "blobs"; why = "a media or design file"
  } else if (b ~ /\.(sqlite|sqlite3|db|dump|mdb)$/) {
    cat = "blobs"; why = "a database file"
  }

  # Size is the last question, and only for a path nothing else claimed: a
  # 40 MB dist bundle is build output, and saying so twice helps nobody.
  if (cat == "") {
    n = bytes(p)
    if (n > max) {
      cat = "blobs"
      why = sprintf("%.1f MB — consider Git LFS or external storage", n / 1000000)
    }
  }

  if (cat != "") printf "%s\t%s\t%s\n", cat, p, why
}
