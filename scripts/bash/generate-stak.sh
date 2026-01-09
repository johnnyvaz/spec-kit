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
            echo "Validates prerequisites for stakeholder documentation generation."
            echo "Checks that spec.md exists and determines if creating new or updating existing spec-stak.md."
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
    echo "The stakeholder documentation (spec-stak.md) is generated from the technical" >&2
    echo "specification (spec.md), so spec.md must exist before running this command." >&2
    exit 1
fi

# Define spec-stak.md path
SPEC_STAK="$FEATURE_DIR/spec-stak.md"

# Check if spec-stak.md already exists (for incremental updates)
STAK_EXISTS="false"
if [[ -f "$SPEC_STAK" ]]; then
    STAK_EXISTS="true"
fi

# Get last modified time of spec.md for version tracking
# Use stat command (different between Linux and macOS)
if stat --version >/dev/null 2>&1; then
    # GNU stat (Linux)
    SPEC_MODIFIED=$(stat -c %Y "$FEATURE_SPEC" 2>/dev/null || echo "0")
else
    # BSD stat (macOS)
    SPEC_MODIFIED=$(stat -f %m "$FEATURE_SPEC" 2>/dev/null || echo "0")
fi

# Copy template if creating new spec-stak.md
TEMPLATE="$REPO_ROOT/.specify/templates/spec-stak-template.md"
if [[ "$STAK_EXISTS" == "false" ]]; then
    if [[ -f "$TEMPLATE" ]]; then
        cp "$TEMPLATE" "$SPEC_STAK"
        if [[ "$JSON_MODE" == "false" ]]; then
            echo "Copied spec-stak template to $SPEC_STAK" >&2
        fi
    else
        if [[ "$JSON_MODE" == "false" ]]; then
            echo "Warning: Stakeholder template not found at $TEMPLATE" >&2
            echo "Creating empty spec-stak.md file" >&2
        fi
        # Create a basic file if template doesn't exist
        touch "$SPEC_STAK"
    fi
fi

# Output results
if $JSON_MODE; then
    printf '{"FEATURE_SPEC":"%s","SPEC_STAK":"%s","FEATURE_DIR":"%s","BRANCH":"%s","STAK_EXISTS":"%s","SPEC_MODIFIED":"%s","HAS_GIT":"%s"}\n' \
        "$FEATURE_SPEC" "$SPEC_STAK" "$FEATURE_DIR" "$CURRENT_BRANCH" "$STAK_EXISTS" "$SPEC_MODIFIED" "$HAS_GIT"
else
    echo "FEATURE_SPEC: $FEATURE_SPEC"
    echo "SPEC_STAK: $SPEC_STAK"
    echo "FEATURE_DIR: $FEATURE_DIR"
    echo "BRANCH: $CURRENT_BRANCH"
    echo "STAK_EXISTS: $STAK_EXISTS"
    echo "SPEC_MODIFIED: $SPEC_MODIFIED"
    echo "HAS_GIT: $HAS_GIT"
    echo ""
    if [[ "$STAK_EXISTS" == "true" ]]; then
        echo "Mode: INCREMENTAL UPDATE (spec-stak.md already exists)"
    else
        echo "Mode: CREATE NEW (spec-stak.md will be created)"
    fi
fi
