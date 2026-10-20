#!/bin/bash
# Builds build/Showtime.app (universal when possible) and signs it.
#   --version X.Y.Z   bundle version (default 0.1.0)
#   --sign IDENTITY   codesign identity (default "-", ad-hoc)
set -euo pipefail
cd "$(dirname "$0")/.."

VERSION=0.1.0
IDENTITY="${SIGN_IDENTITY:--}"
while [[ $# -gt 0 ]]; do
  case "$1" in
    --version) VERSION="$2"; shift 2 ;;
    --sign) IDENTITY="$2"; shift 2 ;;
    *) echo "unknown option $1" >&2; exit 2 ;;
  esac
done

BINS=()
for ARCH in arm64 x86_64; do
  if swift build -c release --arch "$ARCH" --product Showtime; then
    BINS+=(".build/$ARCH-apple-macosx/release/Showtime")
  elif [[ "$ARCH" == x86_64 && -z "${CI:-}" ]]; then
    echo "warning: x86_64 build failed; producing an arm64-only app" >&2
  else
    exit 1
  fi
done

APP=build/Showtime.app
rm -rf "$APP"
mkdir -p "$APP/Contents/MacOS" "$APP/Contents/Resources"
lipo -create "${BINS[@]}" -output "$APP/Contents/MacOS/Showtime"
sed "s/__VERSION__/$VERSION/g" Resources/Info.plist > "$APP/Contents/Info.plist"
printf 'APPL????' > "$APP/Contents/PkgInfo"
[[ -f Resources/AppIcon.icns ]] && cp Resources/AppIcon.icns "$APP/Contents/Resources/"

if [[ "$IDENTITY" == "-" ]]; then TS=--timestamp=none; else TS=--timestamp; fi
codesign --force --options runtime --entitlements Resources/Showtime.entitlements $TS -s "$IDENTITY" "$APP"
echo "built $APP ($VERSION, $(lipo -archs "$APP/Contents/MacOS/Showtime"))"
