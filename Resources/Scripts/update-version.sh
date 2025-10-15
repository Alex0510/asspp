#!/bin/zsh

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
SRCROOT="$(cd "$SCRIPT_DIR/../.." && pwd)"
PROJECT_FILE="$SRCROOT/Asspp.xcodeproj/project.pbxproj"
SIDESTORE_JSON="$SRCROOT/Resources/Repos/sidestore.json"

validate_version() {
    local version="$1"
    if [[ ! "$version" =~ ^[0-9]+(\.[0-9]+)*$ ]]; then
        echo "❌ Invalid version format: $version (expected: X.Y or X.Y.Z)"
        return 1
    fi
    return 0
}

validate_build() {
    local build="$1"
    if [[ ! "$build" =~ ^[0-9]+$ ]]; then
        echo "❌ Invalid build format: $build (expected: integer)"
        return 1
    fi
    return 0
}

if [ -f "$PROJECT_FILE" ]; then
    CURRENT_MARKETING=$(grep -o "MARKETING_VERSION = [^;]*" "$PROJECT_FILE" | head -1 | sed 's/MARKETING_VERSION = \([^;]*\)/\1/')
    CURRENT_PROJECT=$(grep -o "CURRENT_PROJECT_VERSION = [^;]*" "$PROJECT_FILE" | head -1 | sed 's/CURRENT_PROJECT_VERSION = \([^;]*\)/\1/')
    echo "Current: $CURRENT_MARKETING.$CURRENT_PROJECT"
else
    echo "❌ Project file not found: $PROJECT_FILE"
    exit 1
fi

MARKETING_VERSION=""
PROJECT_VERSION=""

if [ $# -eq 2 ]; then
    MARKETING_VERSION="$1"
    PROJECT_VERSION="$2"
else
    read "MARKETING_INPUT?Marketing Version [$CURRENT_MARKETING]: "
    read "PROJECT_INPUT?Project Version [$CURRENT_PROJECT]: "
    
    MARKETING_VERSION="${MARKETING_INPUT:-$CURRENT_MARKETING}"
    PROJECT_VERSION="${PROJECT_INPUT:-$CURRENT_PROJECT}"
fi

if ! validate_version "$MARKETING_VERSION"; then
    exit 1
fi

if ! validate_build "$PROJECT_VERSION"; then
    exit 1
fi

COMBINED_VERSION="$MARKETING_VERSION.$PROJECT_VERSION"
echo "New: $COMBINED_VERSION"

read "CONFIRM?Proceed? (y/N): "
if [[ ! "$CONFIRM" =~ ^[Yy]$ ]]; then
    echo "❌ Cancelled"
    exit 1
fi

# Update project.pbxproj
if command -v sed >/dev/null 2>&1; then
    sed -i '' "s/MARKETING_VERSION = [^;]*/MARKETING_VERSION = $MARKETING_VERSION/g" "$PROJECT_FILE"
    sed -i '' "s/CURRENT_PROJECT_VERSION = [^;]*/CURRENT_PROJECT_VERSION = $PROJECT_VERSION/g" "$PROJECT_FILE"
else
    echo "❌ sed command not found"
    exit 1
fi

# Update SideStore JSON
if [ -f "$SIDESTORE_JSON" ]; then
    CURRENT_DATE=$(date -u '+%Y-%m-%dT%H:%M:%S+00:00')
    
    sed -i '' "s/\"version\": \"[^\"]*\"/\"version\": \"$MARKETING_VERSION\"/" "$SIDESTORE_JSON" # needs to be consistent, otherwise sidestore will reject it
    sed -i '' "s/\"versionDate\": \"[^\"]*\"/\"versionDate\": \"$CURRENT_DATE\"/" "$SIDESTORE_JSON"
    sed -i '' "s|\"downloadURL\": \"https://github.com/Lakr233/Asspp/releases/download/[^/]*/Asspp.ipa\"|\"downloadURL\": \"https://github.com/Lakr233/Asspp/releases/download/$COMBINED_VERSION/Asspp.ipa\"|" "$SIDESTORE_JSON"
fi

# Verify changes
if grep -q "MARKETING_VERSION = $MARKETING_VERSION" "$PROJECT_FILE" && \
   grep -q "CURRENT_PROJECT_VERSION = $PROJECT_VERSION" "$PROJECT_FILE"; then
    echo "✅ Project updated"
else
    echo "❌ Project update failed"
    exit 1
fi

if [ -f "$SIDESTORE_JSON" ]; then
    if grep -q "\"version\": \"$MARKETING_VERSION\"" "$SIDESTORE_JSON" && \
       grep -q "\"downloadURL\": \"https://github.com/Lakr233/Asspp/releases/download/$COMBINED_VERSION/Asspp.ipa\"" "$SIDESTORE_JSON"; then
        echo "✅ JSON updated"
    else
        echo "❌ JSON update failed"
        exit 1
    fi
fi

echo "✅ Done: $CURRENT_MARKETING.$CURRENT_PROJECT → $COMBINED_VERSION"
