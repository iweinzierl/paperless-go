#!/usr/bin/env bash
set -euo pipefail

PROJECT_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
cd "$PROJECT_ROOT"

SCREENSHOT_ENV_FILE="$PROJECT_ROOT/scripts/screenshot-env.sh"
if [[ -f "$SCREENSHOT_ENV_FILE" ]]; then
  # shellcheck disable=SC1090
  source "$SCREENSHOT_ENV_FILE"
fi

for ruby_bin_dir in /opt/homebrew/opt/ruby/bin /usr/local/opt/ruby/bin; do
  if [[ -d "$ruby_bin_dir" ]]; then
    export PATH="$ruby_bin_dir:$PATH"
    break
  fi
done

if [[ -z "${JAVA_HOME:-}" ]]; then
  for candidate in \
    "/Applications/Android Studio.app/Contents/jbr/Contents/Home" \
    "/Applications/Android Studio.app/Contents/jre/Contents/Home"; do
    if [[ -d "$candidate" ]]; then
      export JAVA_HOME="$candidate"
      export PATH="$JAVA_HOME/bin:$PATH"
      break
    fi
  done
fi

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
