#!/usr/bin/env bash

set -e

# Parse command line arguments
JSON_MODE=false
GENERATE_MODE=false
TARGET_FILE=""
ARGS=()

for arg in "$@"; do
    case "$arg" in
        --json)
            JSON_MODE=true
            ;;
        --generate)
            GENERATE_MODE=true
            ;;
        --help|-h)
            echo "Usage: $0 [--json] [--generate] [arquivo.md]"
            echo ""
            echo "Options:"
            echo "  --json      Output results in JSON format (for AI agents)"
            echo "  --generate  Generate PDF directly using md-to-pdf"
            echo "  --help      Show this help message"
            echo ""
            echo "Examples:"
            echo "  $0 --json                    # Output paths for AI agent"
            echo "  $0 --generate                # Generate PDF of spec-stak.md"
            echo "  $0 --generate spec.md        # Generate PDF of specific file"
            echo ""
            echo "Generates print-optimized PDF from Markdown with Mermaid diagrams."
            exit 0
            ;;
        *)
            if [[ -z "$TARGET_FILE" && "$arg" == *.md ]]; then
                TARGET_FILE="$arg"
            else
                ARGS+=("$arg")
            fi
            ;;
    esac
done

# Get script directory and load common functions
SCRIPT_DIR="$(CDPATH="" cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$(cd "$SCRIPT_DIR/../.." && pwd)"
source "$SCRIPT_DIR/common.sh"

# Get all paths and variables from common functions
eval $(get_feature_paths)

# Check if we're on a proper feature branch (only for git repos)
check_feature_branch "$CURRENT_BRANCH" "$HAS_GIT" || exit 1

# Ensure the feature directory exists
if [[ ! -d "$FEATURE_DIR" ]]; then
    echo "ERROR: Feature directory not found at $FEATURE_DIR" >&2
    echo "This usually means the feature hasn't been initialized yet." >&2
    exit 1
fi

# Check that spec.md exists (prerequisite)
if [[ ! -f "$FEATURE_SPEC" ]]; then
    echo "ERROR: spec.md not found at $FEATURE_SPEC" >&2
    echo "Run /speckit.specify first to create the feature specification." >&2
    echo "" >&2
    echo "The print command requires spec.md as the primary source of information." >&2
    exit 1
fi

# Define paths
SPEC_STAK="$FEATURE_DIR/spec-stak.md"
SPEC_PDF="$FEATURE_DIR/spec.pdf"
STAK_PDF="$FEATURE_DIR/spec-stak.pdf"
IMAGES_DIR="$FEATURE_DIR/images"

# Check if spec-stak.md exists (optional - for enhanced business content)
STAK_EXISTS="false"
if [[ -f "$SPEC_STAK" ]]; then
    STAK_EXISTS="true"
fi

# Determine target file for PDF generation
if [[ -z "$TARGET_FILE" ]]; then
    # Default: use spec-stak.md if exists, otherwise spec.md
    if [[ "$STAK_EXISTS" == "true" ]]; then
        TARGET_FILE="$SPEC_STAK"
        OUTPUT_PDF="$STAK_PDF"
    else
        TARGET_FILE="$FEATURE_SPEC"
        OUTPUT_PDF="$SPEC_PDF"
    fi
else
    # Convert relative path to absolute if needed
    if [[ ! "$TARGET_FILE" = /* ]]; then
        TARGET_FILE="$FEATURE_DIR/$TARGET_FILE"
    fi
    OUTPUT_PDF="${TARGET_FILE%.md}.pdf"
fi

# Generate mode: actually create the PDF
if $GENERATE_MODE; then
    echo "📄 Gerando PDF: $TARGET_FILE"
    echo ""

    # Check if Node.js script exists
    PDF_SCRIPT="$REPO_ROOT/scripts/node/md-to-pdf.js"
    if [[ ! -f "$PDF_SCRIPT" ]]; then
        echo "ERROR: Script md-to-pdf.js not found at $PDF_SCRIPT" >&2
        echo "Fallback: Using npx md-to-pdf directly..." >&2
        echo ""

        # Fallback to direct md-to-pdf (without Mermaid rendering)
        if command -v npx &> /dev/null; then
            npx md-to-pdf "$TARGET_FILE" --pdf-options '{"format": "A4", "margin": "20mm", "printBackground": true}'
            echo ""
            echo "✓ PDF gerado: $OUTPUT_PDF"
            echo "⚠️  Nota: Diagramas Mermaid podem não ter renderizado."
            echo "   Para renderização completa, instale: npm install puppeteer"
        else
            echo "ERROR: npx não encontrado. Instale Node.js." >&2
            exit 1
        fi
    else
        # Use full script with Mermaid support
        node "$PDF_SCRIPT" "$TARGET_FILE"
    fi

    exit 0
fi

# JSON mode: output paths for AI agent integration
if $JSON_MODE; then
    printf '{"FEATURE_SPEC":"%s","SPEC_STAK":"%s","SPEC_PDF":"%s","STAK_PDF":"%s","FEATURE_DIR":"%s","BRANCH":"%s","STAK_EXISTS":"%s","HAS_GIT":"%s","IMAGES_DIR":"%s"}\n' \
        "$FEATURE_SPEC" "$SPEC_STAK" "$SPEC_PDF" "$STAK_PDF" "$FEATURE_DIR" "$CURRENT_BRANCH" "$STAK_EXISTS" "$HAS_GIT" "$IMAGES_DIR"
else
    echo "FEATURE_SPEC: $FEATURE_SPEC"
    echo "SPEC_STAK: $SPEC_STAK"
    echo "SPEC_PDF: $SPEC_PDF"
    echo "STAK_PDF: $STAK_PDF"
    echo "FEATURE_DIR: $FEATURE_DIR"
    echo "BRANCH: $CURRENT_BRANCH"
    echo "STAK_EXISTS: $STAK_EXISTS"
    echo "HAS_GIT: $HAS_GIT"
    echo "IMAGES_DIR: $IMAGES_DIR"
    echo ""
    if [[ "$STAK_EXISTS" == "true" ]]; then
        echo "Mode: FULL (Business + Technical content available)"
        echo ""
        echo "Para gerar PDF:"
        echo "  $0 --generate              # Gera PDF do spec-stak.md"
        echo "  $0 --generate spec.md      # Gera PDF do spec.md"
    else
        echo "Mode: TECHNICAL ONLY (spec-stak.md not found - run /stak for business content)"
        echo ""
        echo "Para gerar PDF:"
        echo "  $0 --generate              # Gera PDF do spec.md"
    fi
fi
