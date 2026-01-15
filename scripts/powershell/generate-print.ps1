#!/usr/bin/env pwsh
# Generate print-optimized PDF for a feature specification

[CmdletBinding()]
param(
    [switch]$Json,
    [switch]$Generate,
    [string]$TargetFile,
    [switch]$Help
)

$ErrorActionPreference = 'Stop'

# Show help if requested
if ($Help) {
    Write-Output "Usage: ./generate-print.ps1 [-Json] [-Generate] [-TargetFile <arquivo.md>] [-Help]"
    Write-Output ""
    Write-Output "Options:"
    Write-Output "  -Json        Output results in JSON format (for AI agents)"
    Write-Output "  -Generate    Generate PDF directly using md-to-pdf"
    Write-Output "  -TargetFile  Specific markdown file to convert"
    Write-Output "  -Help        Show this help message"
    Write-Output ""
    Write-Output "Examples:"
    Write-Output "  ./generate-print.ps1 -Json                    # Output paths for AI agent"
    Write-Output "  ./generate-print.ps1 -Generate                # Generate PDF of spec-stak.md"
    Write-Output "  ./generate-print.ps1 -Generate -TargetFile spec.md  # Generate PDF of specific file"
    Write-Output ""
    Write-Output "Generates print-optimized PDF from Markdown with Mermaid diagrams."
    exit 0
}

# Load common functions
. "$PSScriptRoot/common.ps1"

# Get script directory and repo root
$ScriptDir = $PSScriptRoot
$RepoRoot = (Get-Item $ScriptDir).Parent.Parent.FullName

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
$specPdf = Join-Path $paths.FEATURE_DIR 'spec.pdf'
$stakPdf = Join-Path $paths.FEATURE_DIR 'spec-stak.pdf'
$imagesDir = Join-Path $paths.FEATURE_DIR 'images'

# Check if spec-stak.md exists (optional - for enhanced business content)
$stakExists = "false"
if (Test-Path $specStak) {
    $stakExists = "true"
}

# Determine target file for PDF generation
if ([string]::IsNullOrEmpty($TargetFile)) {
    # Default: use spec-stak.md if exists, otherwise spec.md
    if ($stakExists -eq "true") {
        $TargetFile = $specStak
        $outputPdf = $stakPdf
    } else {
        $TargetFile = $paths.FEATURE_SPEC
        $outputPdf = $specPdf
    }
} else {
    # Convert relative path to absolute if needed
    if (-not [System.IO.Path]::IsPathRooted($TargetFile)) {
        $TargetFile = Join-Path $paths.FEATURE_DIR $TargetFile
    }
    $outputPdf = $TargetFile -replace '\.md$', '.pdf'
}

# Generate mode: actually create the PDF
if ($Generate) {
    Write-Output "📄 Gerando PDF: $TargetFile"
    Write-Output ""

    # Check if Node.js script exists
    $pdfScript = Join-Path $RepoRoot 'scripts/node/md-to-pdf.js'
    if (-not (Test-Path $pdfScript)) {
        Write-Warning "Script md-to-pdf.js not found at $pdfScript"
        Write-Output "Fallback: Using npx md-to-pdf directly..."
        Write-Output ""

        # Fallback to direct md-to-pdf (without Mermaid rendering)
        try {
            $npxPath = Get-Command npx -ErrorAction SilentlyContinue
            if ($npxPath) {
                & npx md-to-pdf $TargetFile --pdf-options '{"format": "A4", "margin": "20mm", "printBackground": true}'
                Write-Output ""
                Write-Output "✓ PDF gerado: $outputPdf"
                Write-Warning "Nota: Diagramas Mermaid podem não ter renderizado."
                Write-Output "   Para renderização completa, instale: npm install puppeteer"
            } else {
                Write-Error "npx não encontrado. Instale Node.js."
                exit 1
            }
        } catch {
            Write-Error "Erro ao gerar PDF: $_"
            exit 1
        }
    } else {
        # Use full script with Mermaid support
        & node $pdfScript $TargetFile
    }

    exit 0
}

# Output results
if ($Json) {
    $result = [PSCustomObject]@{
        FEATURE_SPEC = $paths.FEATURE_SPEC
        SPEC_STAK = $specStak
        SPEC_PDF = $specPdf
        STAK_PDF = $stakPdf
        FEATURE_DIR = $paths.FEATURE_DIR
        BRANCH = $paths.CURRENT_BRANCH
        STAK_EXISTS = $stakExists
        HAS_GIT = $paths.HAS_GIT
        IMAGES_DIR = $imagesDir
    }
    $result | ConvertTo-Json -Compress
} else {
    Write-Output "FEATURE_SPEC: $($paths.FEATURE_SPEC)"
    Write-Output "SPEC_STAK: $specStak"
    Write-Output "SPEC_PDF: $specPdf"
    Write-Output "STAK_PDF: $stakPdf"
    Write-Output "FEATURE_DIR: $($paths.FEATURE_DIR)"
    Write-Output "BRANCH: $($paths.CURRENT_BRANCH)"
    Write-Output "STAK_EXISTS: $stakExists"
    Write-Output "HAS_GIT: $($paths.HAS_GIT)"
    Write-Output "IMAGES_DIR: $imagesDir"
    Write-Output ""
    if ($stakExists -eq "true") {
        Write-Output "Mode: FULL (Business + Technical content available)"
        Write-Output ""
        Write-Output "Para gerar PDF:"
        Write-Output "  ./generate-print.ps1 -Generate                # Gera PDF do spec-stak.md"
        Write-Output "  ./generate-print.ps1 -Generate -TargetFile spec.md  # Gera PDF do spec.md"
    } else {
        Write-Output "Mode: TECHNICAL ONLY (spec-stak.md not found - run /stak for business content)"
        Write-Output ""
        Write-Output "Para gerar PDF:"
        Write-Output "  ./generate-print.ps1 -Generate                # Gera PDF do spec.md"
    }
}
