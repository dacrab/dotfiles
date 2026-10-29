# Pi

Tracks `settings.json` only: model defaults, packages, theme, thinking budgets
and compaction.

Runtime state (sessions, model catalogs, installed packages) and credentials
stay outside the repo under `~/.pi/agent/`; Pi recreates generated files as
needed. `auth.json` is untracked — keep it there with mode `600`.
