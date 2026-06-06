<#
.SYNOPSIS
    Generates a unified master .slnx file from all domain repositories under the Novolis workspace.

.DESCRIPTION
    Scans the Novolis workspace root for all .slnx files, parses their project references,
    and combines them into a single hierarchical master solution file organized by repository.
    All project paths are adjusted to be relative from the workspace root.

.PARAMETER WorkspaceRoot
    The root directory of the Novolis workspace. Defaults to the parent of novolis-governance.

.PARAMETER ExcludeRepos
    Array of repository names to exclude from the master solution.
    Defaults to: '.github', 'novolis-experimental', 'novolis-dogfooding', 'novolis-smoketest', 'novolis-template-dotnet'

.PARAMETER OutputPath
    Path where the master .slnx file will be written.
    Defaults to: <WorkspaceRoot>/novolis-governance/build/Novolis.Platform.slnx

.PARAMETER ValidateProjectReferences
    If $true, validates that all referenced .csproj files exist. Warnings issued for missing files.
    Defaults to $true

.PARAMETER Verbose
    Shows detailed progress for each repository and project processed.

.EXAMPLE
    .\Generate-Platform-Slnx.ps1
    # Generates master .slnx using defaults

    .\Generate-Platform-Slnx.ps1 -Verbose
    # Generates with detailed progress output

    .\Generate-Platform-Slnx.ps1 -WorkspaceRoot "d:\novolis" -ValidateProjectReferences $false
    # Generates without validating project file existence
#>

[CmdletBinding()]
param(
    [Parameter(Mandatory = $false)]
    [string]$WorkspaceRoot,
    
    [Parameter(Mandatory = $false)]
    [string[]]$ExcludeRepos = @(
        '.github',
        'novolis-experimental',
        'novolis-dogfooding',
        'novolis-smoketest',
        'novolis-template-dotnet'
    ),
    
    [Parameter(Mandatory = $false)]
    [string]$OutputPath,
    
    [Parameter(Mandatory = $false)]
    [bool]$ValidateProjectReferences = $true
)

# ============================================================================
# Configuration & Initialization
# ============================================================================

# Determine workspace root if not provided
if (-not $WorkspaceRoot) {
    $scriptDir = Split-Path -Parent $MyInvocation.MyCommand.Path
    # Script is at: <WorkspaceRoot>/novolis-governance/build/Generate-Platform-Slnx.ps1
    # Go up 3 levels to workspace root
    $WorkspaceRoot = Split-Path -Parent (Split-Path -Parent $scriptDir)
}

# Validate workspace root exists
if (-not (Test-Path -PathType Container $WorkspaceRoot)) {
    throw "Workspace root does not exist: $WorkspaceRoot"
}

Write-Verbose "Workspace root: $WorkspaceRoot"

# Determine output path if not provided
if (-not $OutputPath) {
    $OutputPath = Join-Path $WorkspaceRoot "Novolis.Platform.slnx"
}

Write-Verbose "Output path: $OutputPath"

# Create output directory if it doesn't exist
$OutputDir = Split-Path -Parent $OutputPath
if (-not (Test-Path -PathType Container $OutputDir)) {
    New-Item -ItemType Directory -Path $OutputDir -Force | Out-Null
}

$stats = @{
    RepositoriesFound = 0
    RepositoriesIncluded = 0
    ProjectsIncluded = 0
    MissingProjects = 0
    Warnings = @()
}

# ============================================================================
# Phase 1: Discovery & Validation
# ============================================================================

Write-Verbose "Phase 1: Discovering repositories..."

# Find all .slnx files
$slnxFiles = Get-ChildItem -Path $WorkspaceRoot -Filter "*.slnx" -File -Depth 1 | 
    Where-Object { $_.DirectoryName -ne $WorkspaceRoot } |
    Sort-Object Name

if ($slnxFiles.Count -eq 0) {
    throw "No .slnx files found in workspace"
}

$stats.RepositoriesFound = @($slnxFiles | Group-Object DirectoryName).Count
Write-Verbose "Found $($stats.RepositoriesFound) repositories with .slnx files"

# Group .slnx files by repository directory (to handle repos with multiple .slnx files)
$reposByDirectory = $slnxFiles | Group-Object DirectoryName

$reposToProcess = @()

foreach ($repoGroup in $reposByDirectory) {
    $repoDir = $repoGroup.Name
    $repoName = Split-Path -Leaf $repoDir
    
    # Check if repo is in exclude list
    if ($repoName -in $ExcludeRepos) {
        Write-Verbose "Excluding repository: $repoName"
        continue
    }
    
    $reposToProcess += [PSCustomObject]@{
        Name = $repoName
        Directory = $repoDir
        SlnxFiles = $repoGroup.Group.FullName  # Array of all .slnx files in this repo
    }
}

$stats.RepositoriesIncluded = $reposToProcess.Count
Write-Verbose "Including $($reposToProcess.Count) repositories"

# ============================================================================
# Phase 2: Parse and Assemble
# ============================================================================

Write-Verbose "Phase 2: Parsing and assembling master solution..."

# Create master XML document
[xml]$masterSolution = '<Solution></Solution>'

foreach ($repo in $reposToProcess | Sort-Object Name) {
    Write-Verbose "Processing repository: $($repo.Name)"
    
    # Process all .slnx files in this repository (most repos have 1, but some like wirefish have 2)
    foreach ($slnxFilePath in $repo.SlnxFiles) {
        $slnxFileName = Split-Path -Leaf $slnxFilePath
        Write-Verbose "  Processing solution file: $slnxFileName"
        
        # Read the repo's .slnx file
        [xml]$repoSlnx = Get-Content -Path $slnxFilePath -Raw
        
        # Process each folder in this solution file
        foreach ($sourceFolder in $repoSlnx.Solution.Folder) {
            $folderName = $sourceFolder.GetAttribute("Name")
            
            # Create combined folder name
            $combinedFolderName = "/$($repo.Name)$folderName"
            Write-Verbose "    Processing folder: $combinedFolderName"
            
            # Check if this folder already exists in the master solution
            $existingFolder = $null
            foreach ($masterFolderElement in $masterSolution.Solution.Folder) {
                if ($masterFolderElement -and $masterFolderElement.GetAttribute("Name") -eq $combinedFolderName) {
                    $existingFolder = $masterFolderElement
                    break
                }
            }
            
            if ($existingFolder) {
                # Folder already exists, we'll add projects to it
                $masterFolder = $existingFolder
                Write-Verbose "      (Merging with existing folder)"
            }
            else {
                # Create new folder in master solution
                $masterFolder = $masterSolution.CreateElement("Folder")
                $masterFolder.SetAttribute("Name", $combinedFolderName)
                $masterSolution.DocumentElement.AppendChild($masterFolder) | Out-Null
            }
            
            # Process each project in this folder
            foreach ($sourceProject in $sourceFolder.Project) {
                $projectPath = $sourceProject.GetAttribute("Path")
                
                # Adjust path: prepend repo name to make it relative from workspace root
                $adjustedPath = Join-Path $repo.Name $projectPath
                
                # Check if this project already exists in this folder
                $projectExists = $false
                foreach ($masterProjectElement in $masterFolder.Project) {
                    if ($masterProjectElement -and $masterProjectElement.GetAttribute("Path") -eq $adjustedPath) {
                        $projectExists = $true
                        break
                    }
                }
                
                if ($projectExists) {
                    Write-Verbose "      Skipping duplicate project: $adjustedPath"
                    continue
                }
                
                Write-Verbose "      Adding project: $adjustedPath"
                
                # Validate project file exists if requested
                if ($ValidateProjectReferences) {
                    $fullProjectPath = Join-Path $WorkspaceRoot $adjustedPath
                    if (-not (Test-Path -Path $fullProjectPath)) {
                        $warning = "Missing project file: $adjustedPath (full path: $fullProjectPath)"
                        $stats.Warnings += $warning
                        $stats.MissingProjects++
                        Write-Warning $warning
                        continue
                    }
                }
                
                # Create project element
                $project = $masterSolution.CreateElement("Project")
                $project.SetAttribute("Path", $adjustedPath)
                $masterFolder.AppendChild($project) | Out-Null
                
                $stats.ProjectsIncluded++
            }
        }
    }
}

# ============================================================================
# Phase 3: Output & Validation
# ============================================================================

Write-Verbose "Phase 3: Writing and validating output..."

# Format XML with proper indentation
$masterSolution.PreserveWhitespace = $false
$settings = New-Object System.Xml.XmlWriterSettings
$settings.Indent = $true
$settings.IndentChars = "  "
$settings.Encoding = [System.Text.Encoding]::UTF8
$settings.NewLineOnAttributes = $false

$stringWriter = New-Object System.IO.StringWriter
$xmlWriter = [System.Xml.XmlWriter]::Create($stringWriter, $settings)
$masterSolution.WriteTo($xmlWriter)
$xmlWriter.Flush()
$xmlWriter.Close()
$xmlContent = $stringWriter.ToString()

# Write to file with UTF-16 BOM (standard for .slnx files)
Set-Content -Path $OutputPath -Value $xmlContent -Encoding Unicode

Write-Verbose "Master solution written to: $OutputPath"

# Validate output file
if (-not (Test-Path -Path $OutputPath)) {
    throw "Failed to write output file: $OutputPath"
}

# Verify XML is valid by parsing it
try {
    [xml]$null = Get-Content -Path $OutputPath
    Write-Verbose "XML validation: PASSED"
}
catch {
    throw "Generated XML is invalid: $_"
}

# ============================================================================
# Summary & Reporting
# ============================================================================

Write-Host ""
Write-Host "================================================" -ForegroundColor Cyan
Write-Host "Novolis Platform Solution Generation Complete" -ForegroundColor Cyan
Write-Host "================================================" -ForegroundColor Cyan
Write-Host ""
Write-Host "Output File:           $OutputPath" -ForegroundColor Green
Write-Host "Repositories Found:    $($stats.RepositoriesFound)"
Write-Host "Repositories Included: $($stats.RepositoriesIncluded)"
Write-Host "Total Projects:        $($stats.ProjectsIncluded)"
Write-Host ""

if ($stats.MissingProjects -gt 0) {
    Write-Host "⚠ Warnings:            $($stats.MissingProjects) missing project references" -ForegroundColor Yellow
    foreach ($warning in $stats.Warnings) {
        Write-Host "  - $warning" -ForegroundColor Yellow
    }
}
else {
    Write-Host "Validation:            ✓ All project references valid" -ForegroundColor Green
}

Write-Host ""
Write-Host "File size:             $((Get-Item $OutputPath).Length) bytes"
Write-Host ""
Write-Host "Next steps:" -ForegroundColor Cyan
Write-Host "  1. Review the generated solution: $OutputPath"
Write-Host "  2. Open in Visual Studio: File > Open > Solution"
Write-Host "  3. Verify all projects load correctly"
Write-Host ""

# Return summary object
$summary = @{
    OutputPath = $OutputPath
    RepositoriesFound = $stats.RepositoriesFound
    RepositoriesIncluded = $stats.RepositoriesIncluded
    TotalProjects = $stats.ProjectsIncluded
    MissingProjects = $stats.MissingProjects
    Warnings = $stats.Warnings
}

return $summary
