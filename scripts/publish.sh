#!/bin/zsh
# Publish the complete tracked source and localized DMG to this GitHub repository.
# Requires GitHub CLI authentication and a clean, already pushed commit.
set -euo pipefail
PROJECT_DIR="$(cd "$(dirname "$0")/.." && pwd)"
cd "$PROJECT_DIR"
REPO=$(gh repo view "$(git remote get-url origin)" --json nameWithOwner --jq .nameWithOwner)
if [[ "$REPO" == "robbietilton/Compositor" ]]; then
  echo 'Set origin to your own fork before publishing.' >&2
  exit 1
fi
if [[ -n "$(git status --porcelain)" ]]; then
  echo 'Commit and push source changes before publishing.' >&2
  exit 1
fi
TAG=${RELEASE_TAG:-v1.4.7-zh-Hans.1}
DIST="$PROJECT_DIR/dist"
DMG="$DIST/Compositor-1.4.7-zh-Hans-arm64.dmg"
SOURCE="$DIST/Compositor-1.4.7-zh-Hans-source.zip"
[[ -f "$DMG" ]] || { echo 'Run scripts/release.sh first.' >&2; exit 1; }
git archive --format=zip --prefix=Compositor-1.4.7-zh-Hans/ HEAD > "$SOURCE"
(cd "$DIST" && shasum -a 256 "${DMG:t}" "${SOURCE:t}" > SHA256SUMS.txt)
gh release create "$TAG" "$DMG" "$SOURCE" "$DIST/SHA256SUMS.txt" \
  --repo "$REPO" --target "$(git rev-parse HEAD)" \
  --title 'Compositor 1.4.7 简体中文版 · Apple 芯片' \
  --notes "${RELEASE_NOTES:-完整 MIT 开源汉化版本，适用于 Apple 芯片 Mac，要求 macOS 26.0 或以上。采用临时签名，未经过 Apple 公证。详见仓库 README.md 和 VALIDATION.md。}"
