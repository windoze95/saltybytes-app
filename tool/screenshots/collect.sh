#!/usr/bin/env bash
# Copies the freshly shot screenshots + feature graphic into the two fastlane
# store layouts (run tool/screenshots/build.sh first):
#   ios/fastlane/screenshots/en-US/            iphone69_* + ipad13_*
#   android/fastlane/metadata/android/en-US/images/
#     phoneScreenshots/ tenInchScreenshots/ featureGraphic.png
set -euo pipefail

cd "$(dirname "$0")"
OUT=out
IOS_DIR=../../ios/fastlane/screenshots/en-US
PLAY_DIR=../../android/fastlane/metadata/android/en-US/images

rm -f "$IOS_DIR"/iphone69_*.png "$IOS_DIR"/ipad13_*.png
mkdir -p "$IOS_DIR" "$PLAY_DIR/phoneScreenshots" "$PLAY_DIR/tenInchScreenshots"

for f in "$OUT"/iphone69/*.png; do
  cp "$f" "$IOS_DIR/iphone69_$(basename "$f")"
done
for f in "$OUT"/ipad13/*.png; do
  cp "$f" "$IOS_DIR/ipad13_$(basename "$f")"
done

rm -f "$PLAY_DIR"/phoneScreenshots/*.png "$PLAY_DIR"/tenInchScreenshots/*.png
cp "$OUT"/android/*.png "$PLAY_DIR/phoneScreenshots/"
cp "$OUT"/tablet10/*.png "$PLAY_DIR/tenInchScreenshots/"
cp "$OUT"/featureGraphic.png "$PLAY_DIR/featureGraphic.png"

echo "synced:"
ls "$IOS_DIR" | head -20
ls "$PLAY_DIR/phoneScreenshots"
