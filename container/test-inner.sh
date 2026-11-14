#!/usr/bin/env bash
# SPDX-FileCopyrightText: 2026 Alberto P.
# SPDX-License-Identifier: MPL-2.0
#
# Runs inside a throwaway, network-less container (started by ../test.sh).
# Usage: test-inner.sh <path-to.AppImage>
set -uo pipefail

failed=0
pass() { echo "PASS: $*"; }
fail() { echo "FAIL: $*"; failed=1; }
# check DESCRIPTION CMD...: run CMD quietly, report the result.
check() {
    local what=$1; shift
    if "$@" >/dev/null 2>&1; then pass "$what"; else fail "$what"; fi
}

mkdir -p /tmp/test && cd /tmp/test || exit 1
cp "$1" app.AppImage
./app.AppImage --appimage-extract >/dev/null 2>&1 || { fail "extract"; exit 1; }
pass "extract"

root=squashfs-root/opt/arubasign
for dir in app/lin-x64 asp/lin-x64 runtime/jreLin64; do
    check "layout: $dir" test -d "$root/$dir"
done
check "Electron binary is executable" test -x "$root/app/lin-x64/ArubaSign"
check "bundled JRE runs" "$root/runtime/jreLin64/bin/java" -version

if ldd "$root/app/lin-x64/ArubaSign" 2>&1 | grep -q 'not found'; then
    fail "missing shared libraries:"; ldd "$root/app/lin-x64/ArubaSign" | grep 'not found'
else
    pass "no missing shared libraries"
fi
check "desktop file is valid" desktop-file-validate squashfs-root/arubasign.desktop

# Headless start: the app must still be running when the timeout kills it.
export HOME=/tmp/home; mkdir -p "$HOME"
xvfb-run -a timeout 10 ./app.AppImage >/tmp/run.log 2>&1
status=$?
if [ "$status" -eq 124 ]; then
    pass "app stays up for 10 s"
else
    fail "app exited early (status $status)"; tail -20 /tmp/run.log
fi
exit "$failed"
