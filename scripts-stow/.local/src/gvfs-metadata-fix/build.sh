#!/usr/bin/env bash
# Rebuild and reinstall the patched gvfsd-metadata (see README.md).
set -euo pipefail

here=$(cd "$(dirname "$0")" && pwd)
version=1.60.3
url="https://download.gnome.org/sources/gvfs/${version%.*}/gvfs-${version}.tar.xz"
prefix="$HOME/.local/opt/gvfs-metadata-patched"
# Build outside the dotfiles tree, which is version controlled.
src="${XDG_CACHE_HOME:-$HOME/.cache}/gvfs-metadata-fix"

mkdir -p "$src"
cd "$src"
[ -f "gvfs-$version.tar.xz" ] || curl -fL -o "gvfs-$version.tar.xz" "$url"
rm -rf "gvfs-$version"
tar xf "gvfs-$version.tar.xz"
cd "gvfs-$version"

patch -p1 < "$here/0001-metadata-use-hash-table-for-pending-notifications.patch"

# gsettings-desktop-schemas is only needed for the parts of gvfs we do not
# build (the core daemon and its backends); a stub .pc file is enough.
mkdir -p "$src/fakepc"
cat > "$src/fakepc/gsettings-desktop-schemas.pc" <<'EOF'
prefix=/usr
Name: gsettings-desktop-schemas
Description: stub for a metadata-only build
Version: 48.0
EOF

rm -rf _build
PKG_CONFIG_PATH="$src/fakepc" meson setup _build --prefix="$prefix" \
  -Dadmin=false -Dafc=false -Dafp=false -Darchive=false -Dcdda=false \
  -Ddnssd=false -Dgoa=false -Dgphoto2=false -Dhttp=false -Dmtp=false \
  -Dnfs=false -Donedrive=false -Dsftp=false -Dsmb=false -Dudisks2=false \
  -Dwsdd=false -Dbluray=false -Dfuse=false -Dgcr=false -Dgcrypt=false \
  -Dgudev=false -Dkeyring=false -Dlogind=false -Dlibusb=false \
  -Dsystemduserunitdir=no -Ddevel_utils=false
ninja -C _build
ninja -C _build install

# The metadata daemon is all we run from this prefix; drop the core daemon,
# the backends and the data files that `ninja install` also produces.
find "$prefix/libexec" -mindepth 1 ! -name gvfsd-metadata -delete
find "$prefix/lib64/gvfs" -mindepth 1 ! -name libgvfscommon.so -delete
rm -rf "$prefix/share" "$prefix/lib64/gio" "$prefix/bin"

echo
echo "Installed to $prefix"
echo "Restart the daemon with: systemctl --user restart gvfs-metadata.service"
