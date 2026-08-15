# Files that usually should NOT be committed

Use this catalog to screen the files about to enter a commit. A candidate that matches a category below should be flagged to the user before committing. This is a heuristic — some projects legitimately commit a few of these (e.g. a committed `vendor/` in Go, or a `.env.example`), so present findings as a warning and let the user decide.

Only newly added / untracked files are worth flagging — `.gitignore` cannot un-track a file that is already tracked in git.

## Secrets & credentials (highest priority — never commit)

Committing a secret means it must be rotated even after removal, since it lives in history.

- `.env`, `.env.*` (but a checked-in `.env.example` / `.env.sample` is usually fine)
- `*.pem`, `*.key`, `*.p12`, `*.pfx`, `id_rsa`, `id_ed25519`
- `credentials.json`, `secrets.*`, `*.keystore`
- Cloud/config creds: `.aws/credentials`, `.npmrc` with tokens, `.netrc`

## Dependencies (regenerated from a manifest)

- `node_modules/`
- `vendor/` (PHP/Composer, Go modules cache)
- `.venv/`, `venv/`, `env/`, `__pycache__/`, `*.egg-info/`
- `.bundle/`, `Pods/` (CocoaPods)

## Build output & compiled artifacts

- `dist/`, `build/`, `out/`, `target/`, `bin/`, `obj/`
- `*.o`, `*.a`, `*.so`, `*.dll`, `*.exe`, `*.class`, `*.pyc`, `*.pyo`
- `.next/`, `.nuxt/`, `.svelte-kit/`, `.parcel-cache/`

## OS & editor cruft

- `.DS_Store`, `.AppleDouble`, `Thumbs.db`, `Desktop.ini`
- `.idea/`, `.vscode/` (project-specific settings are sometimes committed intentionally)
- `*.swp`, `*.swo`, `*~`, `.\#*`

## Logs, caches & temp

- `*.log`, `logs/`
- `.cache/`, `tmp/`, `temp/`, `.tmp/`
- `coverage/`, `.nyc_output/`, `.pytest_cache/`, `.mypy_cache/`

## Large / binary blobs

Media, archives, datasets, and other large binaries usually don't belong in source control (consider Git LFS or external storage). Flag anything that is:

- A large file (roughly > 5 MB), or
- A binary media/archive: `*.zip`, `*.tar.gz`, `*.mp4`, `*.mov`, `*.psd`, `*.sqlite`, `*.db`, `*.dump`, large `*.csv`/`*.parquet` datasets
