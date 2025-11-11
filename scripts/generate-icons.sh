#!/bin/bash
set -e

# Colors for output
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

SOURCE_IMAGE="$1"

if [ -z "$SOURCE_IMAGE" ]; then
  echo "Usage: $0 <source_image_1024x1024.png>"
  exit 1
fi

if [ ! -f "$SOURCE_IMAGE" ]; then
  echo "Error: Source image not found: $SOURCE_IMAGE"
  exit 1
fi

echo -e "${GREEN}Generating app icons from $SOURCE_IMAGE...${NC}"

OUTPUT_DIR="SeaCrab/Assets.xcassets/AppIcon.appiconset"

# Check if ImageMagick is installed
if ! command -v magick &> /dev/null && ! command -v convert &> /dev/null; then
  echo -e "${YELLOW}ImageMagick not found. Install with: brew install imagemagick${NC}"
  exit 1
fi

# Use magick or convert depending on ImageMagick version
if command -v magick &> /dev/null; then
  CONVERT="magick"
else
  CONVERT="convert"
fi

# Generate all required icon sizes
echo "Generating 16x16 -> icon_16x16.png"
$CONVERT "$SOURCE_IMAGE" -resize 16x16 "$OUTPUT_DIR/icon_16x16.png"

echo "Generating 32x32 -> icon_16x16@2x.png"
$CONVERT "$SOURCE_IMAGE" -resize 32x32 "$OUTPUT_DIR/icon_16x16@2x.png"

echo "Generating 32x32 -> icon_32x32.png"
$CONVERT "$SOURCE_IMAGE" -resize 32x32 "$OUTPUT_DIR/icon_32x32.png"

echo "Generating 64x64 -> icon_32x32@2x.png"
$CONVERT "$SOURCE_IMAGE" -resize 64x64 "$OUTPUT_DIR/icon_32x32@2x.png"

echo "Generating 128x128 -> icon_128x128.png"
$CONVERT "$SOURCE_IMAGE" -resize 128x128 "$OUTPUT_DIR/icon_128x128.png"

echo "Generating 256x256 -> icon_128x128@2x.png"
$CONVERT "$SOURCE_IMAGE" -resize 256x256 "$OUTPUT_DIR/icon_128x128@2x.png"

echo "Generating 256x256 -> icon_256x256.png"
$CONVERT "$SOURCE_IMAGE" -resize 256x256 "$OUTPUT_DIR/icon_256x256.png"

echo "Generating 512x512 -> icon_256x256@2x.png"
$CONVERT "$SOURCE_IMAGE" -resize 512x512 "$OUTPUT_DIR/icon_256x256@2x.png"

echo "Generating 512x512 -> icon_512x512.png"
$CONVERT "$SOURCE_IMAGE" -resize 512x512 "$OUTPUT_DIR/icon_512x512.png"

echo "Generating 1024x1024 -> icon_512x512@2x.png"
$CONVERT "$SOURCE_IMAGE" -resize 1024x1024 "$OUTPUT_DIR/icon_512x512@2x.png"

echo -e "${GREEN}✓ All icons generated successfully!${NC}"

