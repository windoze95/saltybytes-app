#!/usr/bin/env bash
# One-command store-screenshot run:
#   tool/screenshots/build.sh [--skip-flutter-build]
# Builds the web harness, serves it with the demo images, shoots every device
# size (tool/screenshots/out/), and renders the Play feature graphic.
set -euo pipefail

cd "$(dirname "$0")/../.."
PORT="${PORT:-8787}"

if [ "${1:-}" != "--skip-flutter-build" ]; then
  flutter build web --release -t test/preview/screenshot_main.dart -o build/web_screens
fi

rm -rf build/web_screens/demo build/web_screens/graphic-assets
cp -R tool/screenshots/demo build/web_screens/demo
mkdir -p build/web_screens/graphic-assets
cp ios/Runner/Assets.xcassets/AppIcon.appiconset/Icon-App-1024x1024@1x.png \
  build/web_screens/graphic-assets/icon.png
cp tool/screenshots/featuregraphic.html build/web_screens/featuregraphic.html

python3 -m http.server "$PORT" -d build/web_screens >/dev/null 2>&1 &
SERVER=$!
trap 'kill $SERVER 2>/dev/null' EXIT
sleep 1

cd tool/screenshots
if [ ! -d node_modules ]; then PLAYWRIGHT_SKIP_BROWSER_DOWNLOAD=1 npm install; fi
node shoot.js "http://localhost:$PORT" out "${2:-}" "${3:-}"
node graphic.js "http://localhost:$PORT/featuregraphic.html" out/featureGraphic.png
echo "outputs in tool/screenshots/out/"
