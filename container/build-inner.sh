#!/usr/bin/env bash
# SPDX-FileCopyrightText: 2026 Alberto P.
# SPDX-License-Identifier: MPL-2.0
#
# Runs inside the build container (started by ../build.sh): fetches the vendor
# rpm, lays it out as an AppDir and packs it with linuxdeploy.
# Why the rpm: see docs/analysis.md.
set -euo pipefail

RPM_URL="https://updatesfirma.aruba.it/downloads/ArubaSign-latest-LINUX.rpm"
LINUXDEPLOY_URL="https://github.com/linuxdeploy/linuxdeploy/releases/download"
PLUGIN_URL="https://github.com/linuxdeploy/linuxdeploy-plugin-appimage/releases/download"

# Pinned tool versions and checksums (LINUXDEPLOY_*, PLUGIN_*).
# shellcheck source=/dev/null
. /versions.env

work=/tmp/work
appdir="$work/AppDir"
vendor="$appdir/opt/arubasign"

install_prerequisites() {
    export DEBIAN_FRONTEND=noninteractive
    apt-get update -qq
    apt-get install -y -qq --no-install-recommends \
        curl ca-certificates rpm rpm2cpio cpio file \
        desktop-file-utils squashfs-tools binutils >/dev/null
}

# fetch URL DEST [SHA256]: download once, verify the checksum when given.
fetch() {
    [ -f "$2" ] || curl -fsSL -o "$2" "$1"
    if [ -n "${3:-}" ] && ! echo "$3  $2" | sha256sum -c - >/dev/null; then
        echo "checksum mismatch: $2" >&2
        exit 1
    fi
}

fetch_tools() {
    mkdir -p /cache/tools
    fetch "$LINUXDEPLOY_URL/$LINUXDEPLOY_TAG/linuxdeploy-x86_64.AppImage" \
        /cache/tools/linuxdeploy.AppImage "$LINUXDEPLOY_SHA256"
    fetch "$PLUGIN_URL/$PLUGIN_TAG/linuxdeploy-plugin-appimage-x86_64.AppImage" \
        /cache/tools/linuxdeploy-plugin-appimage.AppImage "$PLUGIN_SHA256"
    chmod +x /cache/tools/*.AppImage
}

# The vendor replaces the file in place under the same URL, so never reuse a
# cached copy; record its checksum for traceability.
fetch_vendor_package() {
    curl -fsSL -o /cache/ArubaSign.rpm "$RPM_URL"
    sha256sum /cache/ArubaSign.rpm | tee /cache/ArubaSign.rpm.sha256
}

build_appdir() {
    rm -rf "$work"
    mkdir -p "$work/pkg" "$appdir/opt"
    (cd "$work/pkg" && rpm2cpio /cache/ArubaSign.rpm | cpio -idm --quiet)
    [ -d "$work/pkg/opt/arubasign/app/lin-x64" ] \
        || { echo "unexpected package layout: vendor changed it?" >&2; exit 1; }

    cp -a "$work/pkg/opt/arubasign" "$vendor"
    # Installer/launcher leftovers that make no sense inside an AppImage.
    rm -f "$vendor/app/lin-x64/"{arubasign.bat,preinstall.sh,postinstall.sh,chrome-sandbox}
    chmod -R u+rwX,go+rX "$vendor"
    chmod +x "$vendor/app/lin-x64/ArubaSign" \
             "$vendor/asp/lin-x64/ArubaSignPlatform.exe" \
             "$vendor/asp/lin-x64/driver/util/"*.exe* \
             "$vendor/runtime/jreLin64/bin/"*
    install -m 755 /assets/AppRun "$appdir/AppRun"
}

pack_appimage() {
    desktop-file-validate /assets/arubasign.desktop
    export VERSION OUTPUT="/out/ArubaSign-$VERSION-x86_64.AppImage"
    export LINUXDEPLOY_OUTPUT_VERSION="$VERSION" APPIMAGE_EXTRACT_AND_RUN=1
    export PATH="/cache/tools:$PATH"
    cd "$work"
    # System libraries are deliberately not bundled: that keeps the glibc
    # requirement low. See README for the libraries expected on the host.
    /cache/tools/linuxdeploy.AppImage --appdir "$appdir" \
        --desktop-file /assets/arubasign.desktop \
        --icon-file "$work/pkg/usr/share/pixmaps/arubasign.png" --icon-filename arubasign \
        --output appimage
    (cd /out && sha256sum "$(basename "$OUTPUT")" > "$(basename "$OUTPUT").sha256")
    ls -l /out
}

install_prerequisites
fetch_tools
fetch_vendor_package
VERSION="$(rpm -qp --queryformat '%{VERSION}' /cache/ArubaSign.rpm)"
echo "ArubaSign version: $VERSION"
build_appdir
pack_appimage
