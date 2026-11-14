#!/usr/bin/env bash
# SPDX-FileCopyrightText: 2026 Alberto P.
# SPDX-License-Identifier: MPL-2.0
#
# Build the ArubaSign AppImage inside a throwaway podman container; the host
# only needs podman. Downloads the vendor rpm from Aruba on every run.
#
#   ./build.sh
#
# Result: out/ArubaSign-<version>-x86_64.AppImage and a matching .sha256 file.
# Environment: BUILD_IMAGE overrides the base image (default: Debian 12, whose
# older glibc keeps the AppImage runnable on a wide range of distributions).
set -euo pipefail

here="$(cd "$(dirname "$0")" && pwd)"
image="${BUILD_IMAGE:-docker.io/library/debian:12-slim}"

mkdir -p "$here/cache" "$here/out"
exec podman run --rm \
    -v "$here/container/build-inner.sh:/build-inner.sh:ro,Z" \
    -v "$here/versions.env:/versions.env:ro,Z" \
    -v "$here/assets:/assets:ro,Z" \
    -v "$here/cache:/cache:Z" \
    -v "$here/out:/out:Z" \
    "$image" bash /build-inner.sh
