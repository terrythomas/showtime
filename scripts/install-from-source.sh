#!/bin/bash
# Builds Showtime on this Mac and installs it to ~/Applications.
# Needs only Apple's Command Line Tools: xcode-select --install
set -euo pipefail
cd "$(dirname "$0")/.."
if ! xcode-select -p >/dev/null 2>&1; then
  echo "Apple's Command Line Tools are needed. Run: xcode-select --install" >&2
  exit 1
fi
scripts/build-app.sh "$@"
pkill -x Showtime 2>/dev/null || true
mkdir -p "$HOME/Applications"
rm -rf "$HOME/Applications/Showtime.app"
cp -R build/Showtime.app "$HOME/Applications/"
open "$HOME/Applications/Showtime.app"
echo "Installed to ~/Applications/Showtime.app"
