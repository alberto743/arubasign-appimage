#!/usr/bin/env bash
# SPDX-FileCopyrightText: 2026 Alberto P.
# SPDX-License-Identifier: MPL-2.0
#
# Test the AppImage on several distributions, each in a throwaway podman
# container. Runtime libraries are installed into a disposable image (network
# on); the test itself runs with --network=none and the image is removed.
#
#   ./test.sh [path/to/ArubaSign.AppImage]     (default: newest in out/)
set -uo pipefail

here="$(cd "$(dirname "$0")" && pwd)"
# shellcheck disable=SC2012  # newest-first listing of our own output dir
app="$(realpath "${1:-$(ls -1t "$here"/out/ArubaSign-*.AppImage | head -1)}")"

# Runs without FUSE inside containers, hence APPIMAGE_EXTRACT_AND_RUN below.
# Libraries Electron needs on the host, plus Xvfb for the headless run.
apt_deps="xvfb xauth file desktop-file-utils libgtk-3-0 libnss3 libasound2 libxss1
  libxtst6 libgbm1 libpcsclite1 libcups2 libatk-bridge2.0-0 libdrm2 libxkbcommon0"
apt_deps=$(tr -s ' \n' ' ' <<<"$apt_deps")
apt_install="apt-get update -qq && DEBIAN_FRONTEND=noninteractive apt-get install -y -qq --no-install-recommends $apt_deps >/dev/null"
dnf_deps="xorg-x11-server-Xvfb xauth file desktop-file-utils gtk3 nss alsa-lib libXScrnSaver
  libXtst mesa-libgbm pcsc-lite-libs cups-libs at-spi2-atk libdrm libxkbcommon"
dnf_deps=$(tr -s ' \n' ' ' <<<"$dnf_deps")
dnf_install="dnf -qy install $dnf_deps >/dev/null"

images=(
    "docker.io/library/debian:12-slim|$apt_install"
    "docker.io/library/ubuntu:22.04|$apt_install"
    "docker.io/library/fedora:42|$dnf_install"
)

status=0
for entry in "${images[@]}"; do
    image=${entry%%|*}
    install=${entry#*|}
    tag="arubasign-test-$(tr -c 'a-z0-9\n' '-' <<<"$image")"
    echo "=== $image"
    if ! printf 'FROM %s\nRUN %s\n' "$image" "$install" \
            | podman build -q -t "$tag" -f - "$here/container" >/dev/null; then
        echo "FAIL: could not build the test image"; status=1; continue
    fi
    podman run --rm --network=none \
        -v "$app:/app.AppImage:ro,Z" \
        -v "$here/container/test-inner.sh:/test-inner.sh:ro,Z" \
        "$tag" env APPIMAGE_EXTRACT_AND_RUN=1 bash /test-inner.sh /app.AppImage || status=1
    podman rmi -f "$tag" >/dev/null
done
exit "$status"
