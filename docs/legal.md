# Legal notes: publishing the AppImage

Not legal advice; confirm with a lawyer / Aruba.

- The package says `license = custom` and ships no EULA or redistribution grant for Aruba's own code. Copyright default (Italian L. 633/1941, EU Dir. 2009/24/EC): **no right to redistribute** without the holder's permission. An AppImage is a modified redistribution of the binaries.
- Bundled third-party parts are redistributable (Electron/Chromium: MIT/BSD; JRE: GPLv2 + Classpath Exception, requires licence texts and source offer), but they do not cover Aruba's code.
- Therefore a workflow that downloads the vendor file and **publishes** the AppImage (Release, Packages, public artifact) is **not recommended without written permission** from ArubaPEC (supporto@arubapec.it).
- Safe model: this repository distributes only the scripts and workflow. Each user builds locally (`./build.sh`) or runs the workflow in their own private fork; the artifact stays private with short retention. The user obtains the software from Aruba's official URL.
- If Aruba grants permission: enable the `publish` job (repo variable `ARUBA_REDISTRIBUTION_APPROVED=true`), keep the bundled licence files, and avoid wording that implies Aruba endorsement or uses its trademarks beyond naming the software.
