# Choice of base package

Compared on 2026-11-14 (all extraction done inside throwaway podman containers).

| | tar.zst | deb | rpm |
|---|---|---|---|
| Download size | 210 MB | 184 MB | **49 MB** |
| Version inside | 25.2.0-1 (built 2026-01-28) | control says 3.6.0-1 (stale) | 25.2.0-1 (built 2026-03-27) |
| Payload | 140 files, 442.9 MB | identical to tar.zst except `/usr/bin/arubasign` | 140 files, **434.9 MB** (binaries stripped by rpmbuild) |
| Extraction tool | tar+zstd | ar+tar | rpm2cpio+cpio (or bsdtar) |

Findings:
- tar.zst and deb carry the same unstripped payload; the rpm has the same file list but different (stripped, newer) binaries in ~50 of 140 files.
  (An earlier comment in `build.sh` claiming tar == rpm was wrong.)
- The deb's control file reports version 3.6.0 while the payload is 25.2.0: do not trust it for versioning.
- rpm exposes a reliable version via `rpm -qp --queryformat %{VERSION}`.

**Decision: use the .rpm.** Smallest download (matters in CI), stripped binaries, trustworthy version metadata.
Fallback: tar.zst (no rpm tooling needed).
Note the vendor URLs are "latest" and overwritten in place, so builds are not reproducible bit-for-bit; the build records the vendor sha256.
