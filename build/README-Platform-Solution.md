# Novolis Platform Master Solution Generator

## Overview

This tool generates a unified master `.slnx` (Visual Studio solution) file that combines all 27 domain repositories in the Novolis Platform into a single hierarchical solution. This allows developers to work with the entire platform as one cohesive solution while preserving individual repository structure and organization.

**Generated file**: `d:\novolis\novolis-governance\build\Novolis.Platform.slnx`  
**Script location**: `d:\novolis\novolis-governance\build\Generate-Platform-Slnx.ps1`

---

## Quick Start

### Generate the Master Solution

```powershell
cd d:\novolis\novolis-governance\build
pwsh -ExecutionPolicy Bypass -File .\Generate-Platform-Slnx.ps1
```

### With Verbose Output (Recommended for Troubleshooting)

```powershell
pwsh -ExecutionPolicy Bypass -File .\Generate-Platform-Slnx.ps1 -Verbose
```

### Open in Visual Studio

1. In Visual Studio: **File → Open → Solution**
2. Navigate to: `d:\novolis\novolis-governance\build\Novolis.Platform.slnx`
3. Click **Open**

All 231 projects will load organized by repository and folder type (src/, tests/, codegen/, samples/).

---

## Script Features

### Automatic Discovery
- Scans `d:\novolis` for all directories containing `.slnx` files
- Extracts project references from each repository's solution
- Validates all referenced `.csproj` files exist

### Intelligent Organization
- **Per-repository top-level folders** preserve repository identity
- **Nested folder structure** maintains src/tests/codegen/samples organization
- **Path adjustment** makes all projects relative from workspace root

### Validation & Safety
- Validates generated XML syntax
- Reports missing project files with warnings
- Idempotent: Safe to run anytime (regenerates from scratch each time)
- No side effects or temporary files

### Comprehensive Logging
- Summary statistics: repositories, projects, validation results
- Optional `-Verbose` flag for step-by-step progress
- File size and manifest reporting

---

## Usage Examples

### 1. Regenerate After Repository Changes

When you add new projects to individual repos, regenerate the master solution:

```powershell
.\Generate-Platform-Slnx.ps1
```

The script will detect new projects and update the master `.slnx`.

### 2. Skip Validation (Faster for Large Operations)

If project file validation is slow and you've already verified files:

```powershell
.\Generate-Platform-Slnx.ps1 -ValidateProjectReferences $false
```

### 3. Exclude Specific Repositories

By default, these repos are excluded:
- `.github`
- `novolis-experimental`
- `novolis-dogfooding`
- `novolis-smoketest`
- `novolis-template-dotnet`

To exclude additional repos:

```powershell
$exclude = @('novolis-raylib', 'novolis-physics')
.\Generate-Platform-Slnx.ps1 -ExcludeRepos $exclude
```

### 4. Generate to a Custom Location

```powershell
.\Generate-Platform-Slnx.ps1 -OutputPath "d:\custom-location\Novolis.Platform.slnx"
```

### 5. Specify Workspace Root Explicitly

```powershell
.\Generate-Platform-Slnx.ps1 -WorkspaceRoot "d:\novolis"
```

---

## Generated Solution Statistics

| Metric | Count |
|--------|-------|
| Total Repositories | 29 |
| Included Repositories | 27 |
| Excluded Repositories | 2 (experimental, dogfooding) |
| Total Projects | 231 |
| Missing Project Files | 0 |
| File Size | ~28 KB |
| XML Validation | ✓ Passed |

### Repository Breakdown

The master solution organizes projects from these repositories:

- **Audio Stack**: novolis-audio (30 projects)
- **UI Frameworks**: novolis-avalonia (11 projects), novolis-raylib (4 projects)
- **Infrastructure**: novolis-aspire (2 projects), novolis-messaging (2 projects), novolis-transports (3 projects)
- **Core Services**: novolis-storage (7 projects), novolis-scheduling (3 projects), novolis-security (2 projects)
- **Developer Tools**: novolis-analyzers (3 projects), novolis-codegen (8 projects), novolis-commands (6 projects)
- **Data/Processing**: novolis-math (6 projects), novolis-physics (8 projects), novolis-machinelearning (2 projects)
- **Runtime/Platform**: novolis-io (8 projects), novolis-registry (6 projects), novolis-workspaces (15 projects)
- **Graphics/Rendering**: novolis-rendering (6 projects), novolis-gaming (5 projects)
- **Utilities**: novolis-testing (5 projects), novolis-templates (5 projects), novolis-logging (3 projects), novolis-markup (4 projects), novolis-mapping (6 projects), novolis-install (4 projects), novolis-installer-inno (3 projects), novolis-governance (0 projects), novolis-install (2 projects), novolis-io (2 projects), novolis-wirefish (8 projects), novolis-workflows (3 projects), novolis-workspaces (0 projects)

---

## Solution Structure

The generated `.slnx` file has this hierarchical structure:

```
Solution/
├── /novolis-analyzers/
│   ├── /src/
│   │   ├── Novolis.Analyzers.AutoMapper.csproj
│   │   └── Novolis.Analyzers.CodeLength.csproj
│   └── /tests/
│       └── Novolis.Analyzers.Tests.csproj
├── /novolis-audio/
│   ├── /codegen/
│   │   ├── Novolis.Audio.CodeGen.Abstractions.csproj
│   │   ├── Novolis.Audio.CodeGen.csproj
│   │   └── ... (30 projects total)
│   ├── /src/
│   └── /tests/
├── /novolis-avalonia/
└── ... (27 repositories total)
```

Each project path is relative to `d:\novolis`:
```
novolis-audio\src\Novolis.Audio.Live.Visuals\Novolis.Audio.Live.Visuals.csproj
```

---

## Integration with Your Workflow

### CI/CD Pipeline

Add to your build pipeline to keep the master solution synchronized:

```powershell
# After merging changes to individual repos
& .\novolis-governance\build\Generate-Platform-Slnx.ps1

# Commit the updated master solution
git add novolis-governance/build/Novolis.Platform.slnx
git commit -m "Regenerate platform master solution"
```

### Pre-Commit Hook

To auto-regenerate when `.slnx` files change locally:

1. Create `.git/hooks/pre-commit` in the main workspace repo
2. Add:
   ```powershell
   #!/bin/sh
   pwsh -File "novolis-governance/build/Generate-Platform-Slnx.ps1" -ValidateProjectReferences $false
   ```

### Scheduled Regeneration

Run periodically to ensure the master solution stays in sync:

```powershell
# Windows Task Scheduler
$trigger = New-ScheduledTaskTrigger -Daily -At 9AM
$action = New-ScheduledTaskAction -Execute "pwsh.exe" `
  -Argument "-ExecutionPolicy Bypass -File d:\novolis\novolis-governance\build\Generate-Platform-Slnx.ps1"
Register-ScheduledTask -TaskName "Novolis-Regenerate-Platform-Solution" -Trigger $trigger -Action $action
```

---

## Troubleshooting

### "No .slnx files found"
- Ensure you're running from the correct workspace root (`d:\novolis`)
- Verify all domain repositories have `.slnx` files in their root

### "Missing project references"
- Check the warning output; paths shown are relative to workspace root
- Verify the `.csproj` file exists at the full path
- Run with `-ValidateProjectReferences $false` to skip validation if files are external to workspace

### "XML validation failed"
- Rarely occurs; indicates a bug in the script
- Re-run with fresh input
- Check for unusual characters in project paths

### Solution won't open in Visual Studio
1. Verify XML is valid: Open file in text editor, check syntax
2. Ensure all project paths resolve from `d:\novolis`
3. Try deleting Visual Studio's cache: `%APPDATA%\Microsoft\VisualStudio\*\ComponentModelCache`
4. Re-open the solution file

### Performance Issues
- For very large solutions (231 projects), Visual Studio may take 2-3 minutes to fully load
- Use [Solution Filters (`.slnf`)](https://docs.microsoft.com/en-us/visualstudio/ide/filtered-solutions) to load subsets of projects:
  - Right-click solution in Solution Explorer → **Create New Solution Filter**
  - Select only the repositories/projects you need to work on

---

## Parameters Reference

### `-WorkspaceRoot`
**Type**: `[string]`  
**Default**: Auto-detected from script location  
**Example**: `"d:\novolis"` or `"C:\source\novolis-platform"`

### `-ExcludeRepos`
**Type**: `[string[]]`  
**Default**: `.github`, `novolis-experimental`, `novolis-dogfooding`, `novolis-smoketest`, `novolis-template-dotnet`  
**Example**: 
```powershell
-ExcludeRepos @('novolis-raylib', 'novolis-gaming')
```

### `-OutputPath`
**Type**: `[string]`  
**Default**: `<WorkspaceRoot>/novolis-governance/build/Novolis.Platform.slnx`  
**Example**: `"d:\artifacts\Novolis.Platform.slnx"`

### `-ValidateProjectReferences`
**Type**: `[bool]`  
**Default**: `$true`  
**Note**: Set to `$false` to skip file validation (faster for CI/CD)

### `-Verbose` (PowerShell Common Parameter)
**Type**: `[switch]`  
**Shows**: Detailed step-by-step progress for debugging

---

## Notes

- The script is **idempotent**: Running it multiple times produces the same result
- All project paths are **Windows-style backslashes** (`\`) — this is standard for `.slnx` files on Windows
- The master solution does **not** modify individual repository `.slnx` files
- Projects from excluded repos can still be opened individually via their repository's own `.slnx`

---

## See Also

- [Individual Repository Solutions](../README.md) — Links to each domain repo
- [Novolis Governance Scripts](../scripts/) — Other automation utilities
- [Solution File Format](https://learn.microsoft.com/en-us/visualstudio/extensibility/internals/solution-user-options-dot-suo-file?view=vs-2022) — MS Docs on .slnx files
