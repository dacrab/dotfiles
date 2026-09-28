# Pi

This package tracks intentional Pi configuration only:

- `settings.json` — model defaults, package list, theme, thinking budgets, compaction
- `models.json` — provider and model definitions; credentials are referenced through environment variables

Runtime state stays outside this package under `~/.pi/agent/`: sessions, missions, model catalogs, installed packages, and credentials. Pi recreates generated files as needed.

## Usage

```bash
stow pi-stow
stow -R pi-stow  # refresh after changing tracked files
stow -D pi-stow  # remove the symlinks
```

`auth.json` and its backups are intentionally not tracked. Keep them at `~/.pi/agent/auth.json` with mode `600`.
