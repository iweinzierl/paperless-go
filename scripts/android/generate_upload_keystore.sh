#!/usr/bin/env bash
set -euo pipefail

PROJECT_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
KEYSTORE_PATH="${KEYSTORE_PATH:-$PROJECT_ROOT/android/upload-keystore.jks}"
KEY_ALIAS="${KEY_ALIAS:-upload}"
VALIDITY_DAYS="${VALIDITY_DAYS:-10000}"
DNAME="${DNAME:-CN=Paperless Go, OU=Internal Testing, O=iweinzierl, L=Berlin, S=Berlin, C=DE}"

if ! command -v keytool >/dev/null 2>&1; then
  echo "keytool is not available. Install a JDK first." >&2
  exit 1
fi

if [[ -f "$KEYSTORE_PATH" ]]; then
  echo "Keystore already exists at $KEYSTORE_PATH" >&2
  exit 1
fi

mkdir -p "$(dirname "$KEYSTORE_PATH")"

echo "Generating upload keystore at $KEYSTORE_PATH"

action=(
  keytool
  -genkeypair
  -v
  -keystore "$KEYSTORE_PATH"
  -alias "$KEY_ALIAS"
  -keyalg RSA
  -keysize 2048
  -validity "$VALIDITY_DAYS"
)

if [[ -n "${STORE_PASSWORD:-}" && -n "${KEY_PASSWORD:-}" ]]; then
  action+=(
    -storepass "$STORE_PASSWORD"
    -keypass "$KEY_PASSWORD"
    -dname "$DNAME"
  )
  echo "Using non-interactive keystore generation from environment variables."
else
  echo "No STORE_PASSWORD/KEY_PASSWORD provided. keytool will prompt interactively."
fi

"${action[@]}"

cat <<EOF

Keystore created.

Next:
1. Copy android/key.properties.example to android/key.properties
2. Fill in these values:
   storeFile=$KEYSTORE_PATH
   keyAlias=$KEY_ALIAS
   storePassword=<your password>
   keyPassword=<your password>
3. Run ./scripts/android/build_signed_aab.sh
EOF
