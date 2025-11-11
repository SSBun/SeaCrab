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
declare -A sizes=(
  ["16"]="icon_16x16.png"
  ["32"]="icon_16x16@2x.png icon_32x32.png"
  ["64"]="icon_32x32@2x.png"
  ["128"]="icon_128x128.png"
  ["256"]="icon_128x128@2x.png icon_256x256.png"
  ["512"]="icon_256x256@2x.png icon_512x512.png"
  ["1024"]="icon_512x512@2x.png"
)

for size in "${!sizes[@]}"; do
  for filename in ${sizes[$size]}; do
    echo "Generating ${size}x${size} -> $filename"
    $CONVERT "$SOURCE_IMAGE" -resize ${size}x${size} "$OUTPUT_DIR/$filename"
  done
done

echo -e "${GREEN}✓ All icons generated successfully!${NC}"

