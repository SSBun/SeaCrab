# Icon Setup Instructions

## App Icon vs Menu Bar Icon

SeaCrab now uses two different icons:
- **App Icon**: The crab icon (shown in Dock, Finder, Applications folder)
- **Menu Bar Icon**: The old sparkle icon (shown in the macOS menu bar)

## How to Replace the App Icon with the Crab Image

### Step 1: Save the Crab Icon

Save the crab icon image (1024x1024 pixels) to your desktop or a known location.
For best results, use a PNG file named `crab_icon_1024.png`.

### Step 2: Generate All Icon Sizes

Run the icon generation script:

```bash
# From the project root directory
./scripts/generate-icons.sh /path/to/crab_icon_1024.png

# Example:
./scripts/generate-icons.sh ~/Desktop/crab_icon_1024.png
```

This will automatically generate all required icon sizes:
- 16x16, 32x32, 128x128, 256x256, 512x512 (1x and 2x variants)

### Step 3: Build and Test

```bash
# Build the project
xcodebuild -scheme SeaCrab -destination 'platform=macOS' build

# Or open in Xcode and build (⌘B)
open SeaCrab.xcodeproj
```

### Step 4: Verify

1. **App Icon**: Look in Finder > Applications folder - should show the crab
2. **Menu Bar Icon**: Look in the menu bar - should show the sparkle icon
3. **Dock**: When app is running, should show the crab icon

## What Changed

### New Files
- `SeaCrab/Assets.xcassets/MenuBarIcon.imageset/` - Separate menu bar icon
- `scripts/generate-icons.sh` - Automated icon generation

### Updated Files
- `SeaCrabApp.swift` - Now uses `MenuBarIcon` for the menu bar
- `scripts/create-dmg.sh` - Includes Applications symlink in DMG
- `.github/workflows/release.yml` - Includes Applications symlink in release DMG

### Icon Asset Structure

```
SeaCrab/Assets.xcassets/
├── AppIcon.appiconset/          # Crab icon (for app)
│   ├── icon_16x16.png
│   ├── icon_16x16@2x.png
│   ├── icon_32x32.png
│   ├── icon_32x32@2x.png
│   ├── icon_128x128.png
│   ├── icon_128x128@2x.png
│   ├── icon_256x256.png
│   ├── icon_256x256@2x.png
│   ├── icon_512x512.png
│   ├── icon_512x512@2x.png
│   └── Contents.json
└── MenuBarIcon.imageset/        # Sparkle icon (for menu bar)
    ├── menubar_icon.png
    └── Contents.json
```

## DMG Changes

The DMG installer now includes an Applications folder symlink:
- Users can drag SeaCrab.app directly to the Applications alias
- Provides standard macOS app installation UX

This applies to both:
- Local DMG creation (`./scripts/create-dmg.sh`)
- GitHub release DMG (automatic on tag push)

