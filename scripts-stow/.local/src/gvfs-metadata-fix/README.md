# gvfsd-metadata: fix quadratic CPU use when many files change at once

Backport of a fix for [GNOME/gvfs#885][issue]: emptying a Trash with N files
sends the metadata daemon N `Remove` calls in a burst, and the daemon keeps a
list of pending `AttributeChanged` notifications that it linearly searched (and
linearly removed from) for every call, so the work grew with N².

The daemon would sit at ~100% CPU for tens of seconds to minutes and take the
whole desktop down with it (load average ~10, apps taking minutes to show a
window). A service restart only cleared the in-memory backlog.

[issue]: https://gitlab.gnome.org/GNOME/gvfs/-/issues/885

## What this does

`0001-metadata-use-hash-table-for-pending-notifications.patch` replaces that
list with a `GHashTable` keyed by `(treefile, path)`, making scheduling,
lookup and removal O(1). The burst then costs O(N) instead of O(N²).

Measured with the upstream reproduction script (20,000 empty files, gvfs 1.60.3
on this machine):

| | daemon busy | CPU | peak RSS |
|---|---|---|---|
| stock 1.60.3 | 44.7 s | 44.2 s | 37 MiB |
| patched | 7.2 s | 4.1 s | 15 MiB |

40,000 files with the patch: 10.8 s CPU (linear), where the stock build would
take roughly four times as long as at 20,000.

## Installed layout

- `~/.local/opt/gvfs-metadata-patched/` — patched daemon and the matching
  private `libgvfscommon.so`, so a later system gvfs update cannot break it
  (only glib/gio, which are stable, are shared with the system).
- `~/.local/bin/gvfsd-metadata-local` — wrapper that runs the patched daemon
  and falls back to `/usr/libexec/gvfsd-metadata` if it is missing.
- `~/.config/systemd/user/gvfs-metadata.service.d/10-patched-binary.conf` —
  points the user service at the wrapper.

The wrapper, the drop-in, this README and `build.sh` are versioned in the
`scripts-stow` package; only the built daemon under `~/.local/opt` is not.

Revert at any time:

```sh
rm -rf ~/.config/systemd/user/gvfs-metadata.service.d \
       ~/.local/opt/gvfs-metadata-patched \
       ~/.local/bin/gvfsd-metadata-local
systemctl --user daemon-reload
systemctl --user restart gvfs-metadata.service
```

## Rebuild

```sh
./build.sh            # downloads and builds gvfs 1.60.3 under ~/.cache, then reinstalls
```

When Fedora ships a gvfs with the upstream fix (or gvfs is upgraded), remove
the override as shown above and delete this directory.
