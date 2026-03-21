#!/usr/bin/env bash
set -euo pipefail

PROJECT_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
cd "$PROJECT_ROOT"

if ! command -v flutter >/dev/null 2>&1; then
  echo "flutter is not available in PATH." >&2
  exit 1
fi

has_key_properties=false
if [[ -f "android/key.properties" ]]; then
  has_key_properties=true
fi

has_env_signing=true
for key in ANDROID_STORE_FILE ANDROID_STORE_PASSWORD ANDROID_KEY_ALIAS ANDROID_KEY_PASSWORD; do
  if [[ -z "${!key:-}" ]]; then
    has_env_signing=false
    break
  fi
done

if [[ "$has_key_properties" != true && "$has_env_signing" != true ]]; then
  echo "Missing release signing configuration." >&2
  echo "Add android/key.properties or export ANDROID_STORE_FILE, ANDROID_STORE_PASSWORD, ANDROID_KEY_ALIAS, and ANDROID_KEY_PASSWORD." >&2
  exit 1
fi

build_args=(build appbundle --release)

if [[ -n "${BUILD_NAME:-}" ]]; then
  build_args+=(--build-name "$BUILD_NAME")
fi

if [[ -n "${BUILD_NUMBER:-}" ]]; then
  build_args+=(--build-number "$BUILD_NUMBER")
fi

flutter "${build_args[@]}"

echo

echo "Signed app bundle created at:"
echo "build/app/outputs/bundle/release/app-release.aab"
