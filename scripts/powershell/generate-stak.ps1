#!/usr/bin/env pwsh
# Generate or update stakeholder documentation for a feature

[CmdletBinding()]
param(
    [switch]$Json,
    [switch]$Help
)

$ErrorActionPreference = 'Stop'

# Show help if requested
if ($Help) {
    Write-Output "Usage: ./generate-stak.ps1 [-Json] [-Help]"
    Write-Output "  -Json     Output results in JSON format"
    Write-Output "  -Help     Show this help message"
    Write-Output ""
    Write-Output "Validates prerequisites for stakeholder documentation generation."
    Write-Output "Checks that spec.md exists and determines if creating new or updating existing spec-stak.md."
    exit 0
}

# Load common functions
. "$PSScriptRoot/common.ps1"

# Get all paths and variables from common functions
$paths = Get-FeaturePathsEnv

# Check if we're on a proper feature branch (only for git repos)
if (-not (Test-FeatureBranch -Branch $paths.CURRENT_BRANCH -HasGit $paths.HAS_GIT)) {
    exit 1
}

# Ensure the feature directory exists
if (-not (Test-Path $paths.FEATURE_DIR)) {
    Write-Error "Feature directory not found at $($paths.FEATURE_DIR)"
    Write-Error "This usually means the feature hasn't been initialized yet."
    exit 1
}

# Check that spec.md exists (prerequisite)
if (-not (Test-Path $paths.FEATURE_SPEC)) {
    Write-Error "spec.md not found at $($paths.FEATURE_SPEC)"
    Write-Error "Run /speckit.specify first to create the feature specification."
    Write-Error ""
    Write-Error "The stakeholder documentation (spec-stak.md) is generated from the technical"
    Write-Error "specification (spec.md), so spec.md must exist before running this command."
    exit 1
}

# Define spec-stak.md path
$specStak = Join-Path $paths.FEATURE_DIR 'spec-stak.md'

# Check if spec-stak.md already exists (for incremental updates)
$stakExists = "false"
if (Test-Path $specStak) {
    $stakExists = "true"
}

# Get last modified time of spec.md for version tracking
$specModified = "0"
if (Test-Path $paths.FEATURE_SPEC) {
    $fileInfo = Get-Item $paths.FEATURE_SPEC
    # Convert to Unix timestamp (seconds since epoch)
    $specModified = [Math]::Floor(($fileInfo.LastWriteTimeUtc - [DateTime]::new(1970, 1, 1)).TotalSeconds)
}

# Copy template if creating new spec-stak.md
$template = Join-Path $paths.REPO_ROOT '.specify/templates/spec-stak-template.md'
if ($stakExists -eq "false") {
    if (Test-Path $template) {
        Copy-Item $template $specStak -Force
        if (-not $Json) {
            Write-Output "Copied spec-stak template to $specStak"
        }
    } else {
        if (-not $Json) {
            Write-Warning "Stakeholder template not found at $template"
            Write-Warning "Creating empty spec-stak.md file"
        }
        # Create a basic file if template doesn't exist
        New-Item -ItemType File -Path $specStak -Force | Out-Null
    }
}

# Output results
if ($Json) {
    $result = [PSCustomObject]@{
        FEATURE_SPEC = $paths.FEATURE_SPEC
        SPEC_STAK = $specStak
        FEATURE_DIR = $paths.FEATURE_DIR
        BRANCH = $paths.CURRENT_BRANCH
        STAK_EXISTS = $stakExists
        SPEC_MODIFIED = $specModified.ToString()
        HAS_GIT = $paths.HAS_GIT
    }
    $result | ConvertTo-Json -Compress
} else {
    Write-Output "FEATURE_SPEC: $($paths.FEATURE_SPEC)"
    Write-Output "SPEC_STAK: $specStak"
    Write-Output "FEATURE_DIR: $($paths.FEATURE_DIR)"
    Write-Output "BRANCH: $($paths.CURRENT_BRANCH)"
    Write-Output "STAK_EXISTS: $stakExists"
    Write-Output "SPEC_MODIFIED: $specModified"
    Write-Output "HAS_GIT: $($paths.HAS_GIT)"
    Write-Output ""
    if ($stakExists -eq "true") {
        Write-Output "Mode: INCREMENTAL UPDATE (spec-stak.md already exists)"
    } else {
        Write-Output "Mode: CREATE NEW (spec-stak.md will be created)"
    }
}
