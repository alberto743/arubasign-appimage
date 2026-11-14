# ArubaSign AppImage

Scripts that turn Aruba's official Linux package of **ArubaSign** (the digital
signature client) into a single-file AppImage that runs on most distributions.

> This repository contains only build scripts. ArubaSign itself is proprietary
> software by ArubaPEC S.p.A. and is downloaded from Aruba at build time. Do
> not redistribute the resulting AppImage without Aruba's permission; see
> [docs/legal.md](docs/legal.md).

## Build

You only need [podman](https://podman.io). Everything else happens inside a
throwaway container.

```sh
./build.sh
```

This downloads the current vendor rpm and writes
`out/ArubaSign-<version>-x86_64.AppImage` plus a `.sha256` file. The rpm is
used rather than the tar.zst or deb because it is much smaller and its
binaries are stripped ([docs/analysis.md](docs/analysis.md)).

## Test

```sh
./test.sh
```

Runs the AppImage on Debian 12, Ubuntu 22.04 and Fedora 42, each in a
disposable container without network access: it checks the contents, the
bundled JRE, shared-library resolution, the desktop file, and that the app
survives a headless start. Smart-card access can't be tested this way, so try
it with a real reader.

## Running it

System libraries are not bundled (this keeps the glibc requirement low), so
the host needs GTK 3, NSS, ALSA, `libpcsclite` and, for smart cards, `pcscd`
and `ccid`. Without FUSE 2, run it with `--appimage-extract-and-run`.
The app starts with `--no-sandbox`, as the vendor launcher does.

## Keeping it current

| What | How |
| --- | --- |
| GitHub Actions versions | Dependabot (`.github/dependabot.yml`) |
| linuxdeploy and its plugin (pinned in `versions.env`) | `update-deps` workflow opens a weekly PR via `scripts/update-deps.sh` |
| Build still works with the latest vendor package | `weekly` workflow; after 3 consecutive failures it opens an issue and disables itself |
| Lint (REUSE, ShellCheck, actionlint) | `build` workflow |

## Layout

```
build.sh, test.sh      entry points (run on the host, need podman)
container/             scripts that run inside the containers
assets/                AppRun and .desktop file packed into the AppImage
scripts/update-deps.sh bumps versions.env
versions.env           pinned linuxdeploy versions and checksums
docs/                  package analysis and legal notes
```

## License

The scripts are licensed under [MPL-2.0](LICENSES/MPL-2.0.txt) and follow the
[REUSE](https://reuse.software) specification. This does not apply to ArubaSign.
