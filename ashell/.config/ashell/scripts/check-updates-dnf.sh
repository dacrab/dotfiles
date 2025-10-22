#!/usr/bin/env bash
set -euo pipefail

# Output format: "package version_from -> version_to" (one per line)
# Parse available upgrades and join with current installed version
dnf -q --refresh list --upgrades 2>/dev/null | awk 'NR>1 {print $1, $2}' | \
while read -r name new; do
  pkg="${name%%.*}"
  cur=$(rpm -q --qf '%{VERSION}-%{RELEASE}' "$pkg" 2>/dev/null | head -n1 || true)
  if [[ -n "$cur" ]]; then
    echo "$pkg $cur -> $new"
  fi
done
