#!/usr/bin/env pwsh
# Generate print-optimized HTML for a feature specification

[CmdletBinding()]
param(
    [switch]$Json,
    [switch]$Help
)

$ErrorActionPreference = 'Stop'

# Show help if requested
if ($Help) {
    Write-Output "Usage: ./generate-print.ps1 [-Json] [-Help]"
    Write-Output "  -Json     Output results in JSON format"
    Write-Output "  -Help     Show this help message"
    Write-Output ""
    Write-Output "Validates prerequisites for print-optimized HTML generation."
    Write-Output "Checks that spec.md exists and determines if spec-stak.md is available."
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
    Write-Error "The print command requires spec.md as the primary source of information."
    exit 1
}

# Define paths
$specStak = Join-Path $paths.FEATURE_DIR 'spec-stak.md'
$printOutput = Join-Path $paths.FEATURE_DIR 'spec-print.html'

# Check if spec-stak.md exists (optional - for enhanced business content)
$stakExists = "false"
if (Test-Path $specStak) {
    $stakExists = "true"
}

# Output results
if ($Json) {
    $result = [PSCustomObject]@{
        FEATURE_SPEC = $paths.FEATURE_SPEC
        SPEC_STAK = $specStak
        PRINT_OUTPUT = $printOutput
        FEATURE_DIR = $paths.FEATURE_DIR
        BRANCH = $paths.CURRENT_BRANCH
        STAK_EXISTS = $stakExists
        HAS_GIT = $paths.HAS_GIT
    }
    $result | ConvertTo-Json -Compress
} else {
    Write-Output "FEATURE_SPEC: $($paths.FEATURE_SPEC)"
    Write-Output "SPEC_STAK: $specStak"
    Write-Output "PRINT_OUTPUT: $printOutput"
    Write-Output "FEATURE_DIR: $($paths.FEATURE_DIR)"
    Write-Output "BRANCH: $($paths.CURRENT_BRANCH)"
    Write-Output "STAK_EXISTS: $stakExists"
    Write-Output "HAS_GIT: $($paths.HAS_GIT)"
    Write-Output ""
    if ($stakExists -eq "true") {
        Write-Output "Mode: FULL (Business + Technical content)"
    } else {
        Write-Output "Mode: TECHNICAL ONLY (spec-stak.md not found - run /stak for business content)"
    }
}
