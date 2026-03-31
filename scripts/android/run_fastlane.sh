#!/usr/bin/env bash
set -euo pipefail

PROJECT_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
cd "$PROJECT_ROOT"

if ! command -v fastlane >/dev/null 2>&1; then
  echo "fastlane is not available in PATH." >&2
  exit 1
fi

if [[ $# -lt 1 ]]; then
  echo "Usage: $0 <lane> [fastlane options]" >&2
  exit 1
fi

if [[ -f "Gemfile" ]] && command -v bundle >/dev/null 2>&1; then
  bundle exec fastlane android "$@"
else
  fastlane android "$@"
fi
