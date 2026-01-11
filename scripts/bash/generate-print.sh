#!/usr/bin/env bash

set -e

# Parse command line arguments
JSON_MODE=false
ARGS=()

for arg in "$@"; do
    case "$arg" in
        --json)
            JSON_MODE=true
            ;;
        --help|-h)
            echo "Usage: $0 [--json]"
            echo "  --json    Output results in JSON format"
            echo "  --help    Show this help message"
            echo ""
            echo "Validates prerequisites for print-optimized HTML generation."
            echo "Checks that spec.md exists and determines if spec-stak.md is available."
            exit 0
            ;;
        *)
            ARGS+=("$arg")
            ;;
    esac
done

# Get script directory and load common functions
SCRIPT_DIR="$(CDPATH="" cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
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
PRINT_OUTPUT="$FEATURE_DIR/spec-print.html"

# Check if spec-stak.md exists (optional - for enhanced business content)
STAK_EXISTS="false"
if [[ -f "$SPEC_STAK" ]]; then
    STAK_EXISTS="true"
fi

# Output results
if $JSON_MODE; then
    printf '{"FEATURE_SPEC":"%s","SPEC_STAK":"%s","PRINT_OUTPUT":"%s","FEATURE_DIR":"%s","BRANCH":"%s","STAK_EXISTS":"%s","HAS_GIT":"%s"}\n' \
        "$FEATURE_SPEC" "$SPEC_STAK" "$PRINT_OUTPUT" "$FEATURE_DIR" "$CURRENT_BRANCH" "$STAK_EXISTS" "$HAS_GIT"
else
    echo "FEATURE_SPEC: $FEATURE_SPEC"
    echo "SPEC_STAK: $SPEC_STAK"
    echo "PRINT_OUTPUT: $PRINT_OUTPUT"
    echo "FEATURE_DIR: $FEATURE_DIR"
    echo "BRANCH: $CURRENT_BRANCH"
    echo "STAK_EXISTS: $STAK_EXISTS"
    echo "HAS_GIT: $HAS_GIT"
    echo ""
    if [[ "$STAK_EXISTS" == "true" ]]; then
        echo "Mode: FULL (Business + Technical content)"
    else
        echo "Mode: TECHNICAL ONLY (spec-stak.md not found - run /stak for business content)"
    fi
fi
