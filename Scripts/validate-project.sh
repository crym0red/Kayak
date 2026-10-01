#!/bin/bash
set -euo pipefail
ROOT="$(cd "$(dirname "$0")/.." && pwd)"
PROJECT="$(find "$ROOT" -maxdepth 3 -type d -name 'KayakSwiftUI.xcodeproj' -print -quit)"
[ -n "$PROJECT" ] || { echo 'ERROR: project missing'; exit 1; }
[ -f "$PROJECT/project.pbxproj" ] || { echo 'ERROR: project.pbxproj missing'; exit 1; }
[ -f "$ROOT/SwiftUIFrontend/Info.plist" ] || { echo 'ERROR: Info.plist missing'; exit 1; }
count=$(find "$ROOT/SwiftUIFrontend/Sources" -maxdepth 1 -name '*.swift' | wc -l | tr -d ' ')
[ "$count" -ge 7 ] || { echo "ERROR: expected Swift sources, found $count"; exit 1; }
echo "Project validation passed: $PROJECT"
