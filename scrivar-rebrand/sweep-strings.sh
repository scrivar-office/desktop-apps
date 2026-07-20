#!/bin/bash
# Scrivar Office rebrand — user-visible name sweep (macOS shell).
# Replaces the product name in display strings only. Re-run after every
# upstream rebase; it is idempotent. Legal notices, copyright headers, and
# bundle-internal identifiers are deliberately NOT touched (AGPL: notices stay).
set -euo pipefail
cd "$(dirname "$0")/.."

FROM="ONLYOFFICE"
TO="Scrivar Office"

# 1. Main menu / window titles (Base storyboard — display strings only; verified
#    the storyboard contains no identifiers embedding the product name).
sed -i '' "s/${FROM}/${TO}/g" macos/ONLYOFFICE/Base.lproj/Main.storyboard

# 2. Localized menu strings (46 languages).
for f in macos/ONLYOFFICE/*.lproj/Main.strings; do
  sed -i '' "s/${FROM}/${TO}/g" "$f"
done

echo "Sweep done:"
grep -c "${TO}" macos/ONLYOFFICE/Base.lproj/Main.storyboard | xargs echo "  storyboard occurrences:"
grep -l "${TO}" macos/ONLYOFFICE/*.lproj/Main.strings | wc -l | xargs echo "  localized files touched:"
