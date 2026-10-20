#!/bin/bash
# Runs the test suite. With only the Command Line Tools installed (no Xcode),
# Swift Testing lives outside the default search paths, so point at it explicitly.
set -euo pipefail
cd "$(dirname "$0")/.."
if [[ "$(xcode-select -p 2>/dev/null)" == *CommandLineTools* ]]; then
  F=/Library/Developer/CommandLineTools/Library/Developer/Frameworks
  L=/Library/Developer/CommandLineTools/Library/Developer/usr/lib
  exec swift test -Xswiftc -F"$F" -Xlinker -F"$F" -Xlinker -rpath -Xlinker "$F" -Xlinker -rpath -Xlinker "$L" "$@"
fi
exec swift test "$@"
