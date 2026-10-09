#!/bin/zsh
# Build and package the localized app using a local ad hoc signature.
set -euo pipefail
PROJECT_DIR="$(cd "$(dirname "$0")/.." && pwd)"
cd "$PROJECT_DIR"
python3 scripts/build-localized.py
STAGE=$(mktemp -d "${TMPDIR:-/tmp}/compositor-zh.XXXXXX")
trap 'rm -rf "$STAGE"' EXIT
cp -R "dist/Compositor 中文版.app" "$STAGE/"
ln -s /Applications "$STAGE/Applications"
cp LICENSE "$STAGE/LICENSE.txt"
cp README.md "$STAGE/README.md"
hdiutil create -volname 'Compositor 中文版' -srcfolder "$STAGE" -ov -format UDZO \
  "dist/Compositor-1.4.7-zh-Hans-arm64.dmg"
hdiutil verify "dist/Compositor-1.4.7-zh-Hans-arm64.dmg"
