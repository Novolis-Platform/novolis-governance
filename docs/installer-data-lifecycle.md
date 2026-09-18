# Installer, data, and Android lifecycle policy

Applies to every product host in [novolis-apps](https://github.com/Novolis-Platform/novolis-apps). Authoritative per-app values live in `build/apps.json`.

## Windows (`windows-inno`)

Required Inno citizenship (enforced by `Novolis.Avalonia.Packaging.Inno` + apps validators):

| Rule | Requirement |
|------|-------------|
| Elevation | `PrivilegesRequired=lowest` — no admin override path |
| Install root | `{localappdata}\Programs\Novolis\<App>` — never Program Files |
| Identity | Stable `AppId` per product across versions and repository moves |
| Upgrades | Stable `AppId` plus `UsePreviousAppDir=yes` (documented exceptions only) |
| Processes | `CloseApplications=yes` with a filter covering **every** payload executable |
| Shortcuts | Per-user Start Menu; desktop shortcut opt-in and unchecked by default |
| Machine scope | No HKLM, services, scheduled tasks, machine-wide env, or privileged shell extensions |
| File associations | Per-user only, declared in the manifest, repaired/removed cleanly |
| Uninstall | Removes installer payload and shortcuts; **preserves** documents, workspaces, saves, settings, and credentials |

Payload, user data, cache, crash logs, and credentials must use separate roots. Uninstall must not recursively delete `%LOCALAPPDATA%\Novolis`.

### Data roots (Windows)

| Kind | Location |
|------|----------|
| Installed binaries | `%LOCALAPPDATA%\Programs\Novolis\<App>` |
| Persistent app data | `%LOCALAPPDATA%\Novolis\<app-key>\` |
| Cache / logs | `%LOCALAPPDATA%\Novolis\<app-key>\cache` (and sibling folders) |
| Credentials | Product-scoped Windows Credential Manager namespace |
| User documents | User-selected paths only — apps do not silently copy whole repositories into app data |

Local debugging follows the same data rules even when a platform is not in `ship`.

## Android (`android-apk`)

| Rule | Requirement |
|------|-------------|
| Documents | System picker / SAF for user-selected files; no broad shared-storage permissions |
| App state | App-private `FilesDir` / cache for tokens, temp files, generated artifacts |
| Network | Declare `INTERNET` only for implemented features; `usesCleartextTraffic=false` |
| Backup | Default `allowBackup=false` for credential/token/offline-viewer apps |
| Identity | Stable `applicationId` + persistent signing key (new key = new app) |
| Versioning | Monotonic `versionCode` derived from release metadata (`NovolisAndroidVersionCode`) |

Permission allowlists, network policy, and signing secret keys are declared per app in `build/apps.json`. Validators fail on undeclared permissions and backup/cleartext violations.

## Privacy inventory

Every shipped app maintains a short privacy/data inventory (permissions, network destinations, storage roots, backup, deletion). Template: `novolis-apps/docs/privacy-template.md`.

## Verification

```powershell
pwsh -File d:\novolis\novolis-apps\scripts\verify-installer-policy.ps1
pwsh -File d:\novolis\novolis-apps\scripts\smoke-installer-script.ps1
pwsh -File d:\novolis\novolis-apps\scripts\verify-android-policy.ps1
```
