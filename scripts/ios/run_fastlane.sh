#!/usr/bin/env bash
set -euo pipefail

PROJECT_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
cd "$PROJECT_ROOT"

IOS_SCREENSHOT_CONFIG_FILE="$PROJECT_ROOT/fastlane/.generated/ios/screenshot_configuration.json"

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

if command -v ruby >/dev/null 2>&1; then
  user_gem_bin="$(ruby -e 'print Gem.bindir(Gem.user_dir)' 2>/dev/null || true)"
  if [[ -n "$user_gem_bin" && -d "$user_gem_bin" ]]; then
    export PATH="$user_gem_bin:$PATH"
  fi
fi

write_ios_screenshot_configuration() {
  mkdir -p "$(dirname "$IOS_SCREENSHOT_CONFIG_FILE")"
  PAPERLESS_SCREENSHOT_DATA_SOURCE="${PAPERLESS_SCREENSHOT_DATA_SOURCE:-live}" \
    /usr/bin/ruby -rjson -e '
      path = ARGV.fetch(0)
      keys = %w[
        PAPERLESS_SCREENSHOT_DATA_SOURCE
        PAPERLESS_SCREENSHOT_SERVER_URL
        PAPERLESS_SCREENSHOT_USERNAME
        PAPERLESS_SCREENSHOT_PASSWORD
        PAPERLESS_SCREENSHOT_DISPLAY_NAME
      ]
      config = keys.each_with_object({}) do |key, values|
        value = ENV[key]
        next if value.nil? || value.empty?

        values[key] = value
      end
      File.write(path, JSON.pretty_generate(config))
    ' "$IOS_SCREENSHOT_CONFIG_FILE"
}

if ! command -v fastlane >/dev/null 2>&1; then
  echo "fastlane is not available in PATH." >&2
  exit 1
fi

if [[ $# -lt 1 ]]; then
  echo "Usage: $0 <lane> [fastlane options]" >&2
  exit 1
fi

if [[ "$1" == "screenshots" ]]; then
  write_ios_screenshot_configuration
fi

if [[ -f "Gemfile" ]] && command -v bundle >/dev/null 2>&1; then
  bundle exec fastlane ios "$@"
else
  fastlane ios "$@"
fi