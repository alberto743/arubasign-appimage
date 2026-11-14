#!/usr/bin/env bash
# SPDX-FileCopyrightText: 2026 Alberto P.
# SPDX-License-Identifier: MPL-2.0
# Bump linuxdeploy and its appimage plugin in versions.env to the latest GitHub
# release, recomputing the sha256 of the downloaded asset. Needs curl, jq, sha256sum.
# Set GITHUB_TOKEN to avoid API rate limits.
set -euo pipefail
cd "$(dirname "$0")/.."
auth=(); [ -z "${GITHUB_TOKEN:-}" ] || auth=(-H "Authorization: Bearer $GITHUB_TOKEN")
tmp="$(mktemp -d)"; trap 'rm -rf "$tmp"' EXIT

bump() { # repo asset prefix
    local repo=$1 asset=$2 p=$3 tag sha
    # Newest versioned release (releases may be flagged pre-release; the rolling
    # "continuous" tag is skipped because its assets change in place).
    tag="$(curl -fsSL "${auth[@]}" "https://api.github.com/repos/$repo/releases?per_page=30" \
        | jq -er '[.[] | select(.draft|not) | select(.tag_name|test("^[0-9]"))] | .[0].tag_name')"
    curl -fsSL -o "$tmp/$asset" "https://github.com/$repo/releases/download/$tag/$asset"
    sha="$(sha256sum "$tmp/$asset" | cut -d' ' -f1)"
    sed -i "s/^${p}_TAG=.*/${p}_TAG=$tag/; s/^${p}_SHA256=.*/${p}_SHA256=$sha/" versions.env
    echo "$repo -> $tag"
}
bump linuxdeploy/linuxdeploy linuxdeploy-x86_64.AppImage LINUXDEPLOY
bump linuxdeploy/linuxdeploy-plugin-appimage linuxdeploy-plugin-appimage-x86_64.AppImage PLUGIN
