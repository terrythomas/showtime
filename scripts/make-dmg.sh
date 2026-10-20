#!/bin/bash
# Usage: scripts/make-dmg.sh build/Showtime.app build/Showtime.dmg
# Signs the DMG too when SIGN_IDENTITY is a real identity (not "-").
set -euo pipefail
APP="$1"
OUT="$2"
STAGE="$(mktemp -d)"
trap 'rm -rf "$STAGE"' EXIT
cp -R "$APP" "$STAGE/"
ln -s /Applications "$STAGE/Applications"
rm -f "$OUT"
hdiutil create -volname Showtime -srcfolder "$STAGE" -format UDZO -ov "$OUT" >/dev/null
if [[ -n "${SIGN_IDENTITY:-}" && "$SIGN_IDENTITY" != "-" ]]; then
  codesign --force --timestamp -s "$SIGN_IDENTITY" "$OUT"
fi
echo "made $OUT"
