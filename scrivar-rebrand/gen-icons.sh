#!/bin/bash
# Scrivar Office — regenerate the macOS AppIcon set from the SVG masters.
# icon-b.svg      = full mark (indigo squircle + white S + 3 editor chips)
# icon-b-16.svg   = chipless variant for 16pt sizes (chips unreadable that small)
# Requires: rsvg-convert (brew install librsvg) + Inter font (brew install --cask font-inter)
set -euo pipefail
cd "$(dirname "$0")"
DEST="../macos/ONLYOFFICE/Images.xcassets/AppIcon.appiconset"

# 16pt class — chipless
rsvg-convert -w 16   -h 16   icon-b-16.svg -o "$DEST/16x16.png"
rsvg-convert -w 32   -h 32   icon-b-16.svg -o "$DEST/32x32.png"
# 32pt and up — full mark
rsvg-convert -w 32   -h 32   icon-b.svg -o "$DEST/32x32-1.png"
rsvg-convert -w 64   -h 64   icon-b.svg -o "$DEST/64x64.png"
rsvg-convert -w 128  -h 128  icon-b.svg -o "$DEST/128x128.png"
rsvg-convert -w 256  -h 256  icon-b.svg -o "$DEST/256x256.png"
rsvg-convert -w 256  -h 256  icon-b.svg -o "$DEST/256x256-1.png"
rsvg-convert -w 512  -h 512  icon-b.svg -o "$DEST/512x512.png"
rsvg-convert -w 512  -h 512  icon-b.svg -o "$DEST/512x512-1.png"
rsvg-convert -w 1024 -h 1024 icon-b.svg -o "$DEST/1024x1024.png"
echo "AppIcon set regenerated:"
ls -la "$DEST"/*.png | awk '{print "  "$5" "$9}'

# Title-bar wordmark (86x20 @1x, 172x40 @2x). light imageset = white text (dark tab bar),
# dark imageset = navy text (light tab bar). Georgia stands in for DM Serif Display (system-safe).
TABS="../macos/ONLYOFFICE/Images.xcassets/Tabs"
rsvg-convert -w 86  -h 20 wordmark-white.svg -o "$TABS/logo-tab-light.imageset/logo_white.png"
rsvg-convert -w 172 -h 40 wordmark-white.svg -o "$TABS/logo-tab-light.imageset/logo_white_2x.png"
rsvg-convert -w 86  -h 20 wordmark-dark.svg  -o "$TABS/logo-tab-dark.imageset/logo.png"
rsvg-convert -w 172 -h 40 wordmark-dark.svg  -o "$TABS/logo-tab-dark.imageset/logo_2x.png"
echo "Wordmark imagesets regenerated."
