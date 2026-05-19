#!/bin/bash

# --- 1. EXTRACT FLUTTER VERSION CODE ---
VERSION_CODE="next_version"

if [ -f "pubspec.yaml" ]; then
    # Finds the line "version: X.Y.Z+123" and extracts the digits after the "+"
    EXTRACTED=$(grep -E "^version:" pubspec.yaml | tr -d '[:space:]' | cut -d'+' -f2 | grep -oE '[0-9]+')
    
    if [ ! -z "$EXTRACTED" ]; then
        VERSION_CODE="$EXTRACTED"
    fi
fi

# Output the version code clearly for the AI Agent to parse
echo "TARGET_ANDROID_VERSION_CODE: $VERSION_CODE"
echo "---GIT_HISTORY_START---"

# --- 2. FETCH GIT HISTORY ---
if [ -z "$(git tag)" ]; then
    git log --oneline --no-merges -n 30
else
    git log $(git describe --tags --abbrev=0)..HEAD --oneline --no-merges
fi