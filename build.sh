#!/bin/bash
set -euo pipefail

ROOT="$(cd "$(dirname "$0")/.." && pwd)"
cd "$ROOT"

SCHEME="${SCHEME:-KayakSwiftUI}"
CONFIGURATION="${CONFIGURATION:-Release}"
BUILD_DIR="${BUILD_DIR:-$ROOT/build}"
DERIVED_DATA="${DERIVED_DATA:-$BUILD_DIR/DerivedData}"
UNSIGNED_IPA="${UNSIGNED_IPA:-$BUILD_DIR/${SCHEME}-unsigned.ipa}"

PROJECT_PATH="${PROJECT_PATH:-$(find "$ROOT" -maxdepth 3 -type d -name "${SCHEME}.xcodeproj" -print -quit)}"
if [ -z "$PROJECT_PATH" ]; then
  echo "ERROR: ${SCHEME}.xcodeproj not found under $ROOT"
  exit 1
fi

echo "==> Xcode project: $PROJECT_PATH"
mkdir -p "$BUILD_DIR"
rm -rf "$DERIVED_DATA"

echo "==> Building unsigned iOS app"
xcodebuild \
  -project "$PROJECT_PATH" \
  -scheme "$SCHEME" \
  -configuration "$CONFIGURATION" \
  -sdk iphoneos \
  -destination "generic/platform=iOS" \
  -derivedDataPath "$DERIVED_DATA" \
  CODE_SIGNING_ALLOWED=NO \
  CODE_SIGNING_REQUIRED=NO \
  AD_HOC_CODE_SIGNING_ALLOWED=NO \
  PRODUCT_NAME=KayakSwiftUI \
  build

APP_PATH="$(find "$DERIVED_DATA/Build/Products" -type d -name '*.app' -path '*iphoneos*' -print -quit)"

if [ -z "$APP_PATH" ] || [ ! -d "$APP_PATH" ]; then
  echo "ERROR: xcodebuild completed but no iOS .app was found."
  exit 1
fi

echo "==> Packaging unsigned IPA"
PAYLOAD="$BUILD_DIR/Payload"
rm -rf "$PAYLOAD"
mkdir -p "$PAYLOAD"
cp -R "$APP_PATH" "$PAYLOAD/"

rm -f "$UNSIGNED_IPA"
(
  cd "$BUILD_DIR"
  /usr/bin/zip -qry "$(basename "$UNSIGNED_IPA")" Payload
)

rm -rf "$PAYLOAD"

echo "======================================"
echo "Unsigned IPA created:"
echo "$UNSIGNED_IPA"
echo "======================================"
