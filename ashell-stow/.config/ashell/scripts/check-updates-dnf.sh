#!/usr/bin/env bash
# check-updates-dnf.sh — list available DNF upgrades
# Output format: "package current_version -> new_version" (one per line)
set -euo pipefail

dnf -q --refresh list --upgrades 2>/dev/null \
  | awk 'NR > 1 { print $1, $2 }' \
  | while read -r name new_version; do
      pkg="${name%%.*}"
      cur_version=$(rpm -q --qf '%{VERSION}-%{RELEASE}' "$pkg" 2>/dev/null | head -n1 || true)
      if [[ -n "$cur_version" ]]; then
        echo "$pkg $cur_version -> $new_version"
      fi
    done
