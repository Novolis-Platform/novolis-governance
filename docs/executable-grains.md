# Novolis executable grains

Novolis has four executable grains. Use the first matching row; do not promote a host to a larger grain merely to obtain a different publishing mechanism.

| Decision | Tool | Utility | App | Lab |
|---|---|---|---|---|
| Audience | .NET / Novolis developer | Technical user handling a file, wire, or device | Person doing a product job or playing a game | Novolis maintainer proving a package integration |
| Primary job | Repeatable operator command | One small technical job | Persistent product session, studio, reader, or game loop | Fast experiment, smoke, benchmark, or API walkthrough |
| Host shape | One `OutputType=Exe` CLI | One `OutputType=Exe`, CLI or tiny UI | Product host; multiple projects/processes are allowed | One small host, with lab-only helpers allowed |
| Distribution | NuGet `PackAsTool` | Executable or framework-dependent zip | Product release channel | Source checkout only |
| Installer | Forbidden | Forbidden | Allowed and required by the declared `Ship` channel | Forbidden |
| `PackAsTool` | Required | Forbidden | Forbidden | Forbidden |
| SDK/runtime | SDK requirement is intentional | SDK/runtime requirement is allowed | Release payload may bundle the runtime | Developer checkout requirement is expected |
| Canonical repository | `novolis-tools` | `novolis-utilities` | `novolis-apps` | `novolis-lab` |
| Library dependencies | `PackageReference`; local ProjectReference substitution only in Platform mode | Same | Same | Same; optional library submodules are for checkout/local iteration, never committed project references |
| Shared host code | No lab shared projects | No lab shared projects | App-private code only | `labs/shared` is allowed for experiments, but graduates must remove it |
| Typical examples | `novolis-coverage`, `novolis-docs`, `novolis-manuscript` | NDJSON explorer, ADB utility, WireFish viewer | Sketch Studio, Repo Studio, Merglyph, GeoPolity, PulseStrip | Hello*, smokes, benches, SceneLab |

## Hard placement rules

- Library repositories contain packable libraries, tests, and repo-private `tools/` only.
- A library repository must not publish a `PackAsTool`, shipped CLI, executable zip, Windows installer, or Android APK.
- All installable .NET tools live in `novolis-tools`, even when their domain library lives elsewhere.
- All no-installer technical executables live in `novolis-utilities`.
- All products and games with a product release channel live in `novolis-apps`.
- `novolis-lab` is the staging ground for “spin up something quickly”; it is not a release catalog.
- A lab graduates by moving its host into exactly one of the three shipping repositories. Its lab-only shared references do not graduate.

## Publishing distinction

“Self-contained” describes the host shape: one executable project that can be run directly. It does not require `dotnet publish --self-contained true`.

- Tools are published as tool packages and installed with `dotnet tool install`.
- Utilities may require the .NET SDK/runtime and are distributed as executable artifacts or framework-dependent zips.
- Apps choose a product channel such as `windows-inno` or `android-apk`.
- Labs are not published.
