#!/usr/bin/env bash
set -euo pipefail
app=${1:?Usage: package.sh APP_PATH OUTPUT_DMG}
output=${2:?Usage: package.sh APP_PATH OUTPUT_DMG}
[[ -d "$app" && "$app" == *.app ]] || { echo 'Expected an existing app bundle' >&2; exit 1; }
base=$(cd -- "$(dirname "$0")" && pwd)
work=$(mktemp -d -t media-knowledge-dmg)
mounted=false
cleanup() {
  if [[ "$mounted" == true ]]; then hdiutil detach "$work/mounted" >/dev/null || true; fi
  rm -rf "$work"
}
trap cleanup EXIT
mkdir -p "$work/staging/.background" "$work/mounted" "$(dirname "$output")"
ditto "$app" "$work/staging/media_knowledge.app"
ln -s /Applications "$work/staging/Applications"
swift "$base/background.swift" "$work/staging/.background/install.png"
hdiutil create -volname 'Media Knowledge' -srcfolder "$work/staging" -fs HFS+ -format UDRW "$work/writable.dmg" >/dev/null
hdiutil attach "$work/writable.dmg" -nobrowse -mountpoint "$work/mounted" >/dev/null
mounted=true
osascript "$base/layout.applescript" "$work/mounted"
test -f "$work/mounted/.DS_Store"
hdiutil detach "$work/mounted" >/dev/null
mounted=false
hdiutil convert "$work/writable.dmg" -format UDZO -imagekey zlib-level=9 -ov -o "$output" >/dev/null
printf 'macOS installer created with drag-to-Applications instructions\n'
