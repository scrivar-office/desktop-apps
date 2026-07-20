#!/bin/bash
# Scrivar Office rebrand — start-page (loginpage) product-name sweep.
# Token-swaps the ONLYOFFICE product name across the 47 per-language locale
# files + source, preserving each language's sentence structure. Idempotent;
# re-run after every upstream rebase, then re-run the grunt build.
# Legal notices in file *headers* (Ascensio copyright) are NOT touched.
set -euo pipefail
cd "$(dirname "$0")/../common/loginpage"

sweep() {
  # Order matters: collapse the long form first so we don't get
  # "Scrivar Office Desktop Editors".
  sed -i '' \
    -e 's/ONLYOFFICE Desktop Editors/Scrivar Office/g' \
    -e 's/ONLYOFFICE Documents/Scrivar Office/g' \
    "$1"
  # Cloud-identity strings (P3): the cloud surface is Scrivar Cloud (the
  # launcher-side sync folder), not a portal. Replace the upstream cloud
  # service name + language-specific cloud phrasings BEFORE the generic
  # product-name rule so they don't collapse to "Scrivar Office".
  sed -i '' \
    -e 's/ONLYOFFICE Cloud Service/Scrivar Cloud/g' \
    -e 's/en ligne avec ONLYOFFICE/en ligne avec Scrivar Cloud/g' \
    -e 's/de ONLYOFFICE cloud/de Scrivar Cloud/g' \
    -e 's/del ONLYOFFICE cloud/del Scrivar Cloud/g' \
    -e 's/núvol de ONLYOFFICE/núvol de Scrivar/g' \
    -e 's/Connect to cloud office/Connect to Scrivar Cloud/g' \
    -e 's/Connect to cloud/Scrivar Cloud/g' \
    "$1"
  # Remaining standalone product-name mentions in translatable STRING VALUES.
  # Restrict to the l10n string keys so we never rewrite code identifiers or
  # the info@onlyoffice.com contact in the header comment.
  # NOTE (P3 fix): the value part must tolerate escaped apostrophes (\')
  # inside single-quoted strings — a plain [^']* stopped at the backslash
  # escape and let "Don\'t … ONLYOFFICE Cloud Service …" survive the P1
  # sweep. (?:[^'\\]|\\.) walks over escape sequences correctly.
  perl -0pi -e "s/(wel\w+|text\w+|btn\w+|link\w+|portal\w+|login\w+|empty\w+|act\w+):(\s*)'((?:[^'\\\\]|\\\\.)*?)ONLYOFFICE((?:[^'\\\\]|\\\\.)*?)'/\$1:\$2'\$3Scrivar Office\$4'/g" "$1"
}

for f in locale/*.js src/locale.js; do sweep "$f"; done

# Start-page format-chip + recent-list sprite retint to the Scrivar palette
# (P1 decision log): word -> indigo, cell -> emerald, slide -> amber,
# pdf -> coral. Pale page-preview tints follow their family. iWork teal,
# diagram violet, golden macro variants and all neutrals stay upstream.
# Edit the SOURCES (res/img/formats-svg, res/img/common-svg) — generated/*
# is a sprite artifact rebuilt by grunt.
for f in res/img/formats-svg/*.svg res/img/common-svg/*.svg; do
  perl -pi -e '
    s/#287ca9/#4F46E5/gi; s/#a9cbdd/#C6C4F2/gi; s/#bed8e5/#C6C4F2/gi;
    s/#3aa133/#10B981/gi; s/#b0d9ad/#B2E8D4/gi; s/#c4e3c2/#B2E8D4/gi;
    s/#f36700/#F59E0B/gi; s/#fac299/#FBDCA8/gi; s/#f9d5c4/#FBDCA8/gi;
    s/#e54d39/#E7564E/gi; s/#f5b8b0/#F6C6C2/gi; s/#f7cac4/#F6C6C2/gi;
  ' "$f"
done

# Format-chip badge gradients (document-creation grid + recent list, defined
# in JS config, panelrecent.js documentTypes) -> Scrivar family gradients.
for f in src/*.js; do
  perl -pi -e '
    s/#4298C5/#6366F1/gi; s/#2D84B2/#4F46E5/gi; s/#287ca9/#4F46E5/gi;
    s/#5BB514/#34D399/gi; s/#318C2B/#10B981/gi; s/#3aa133/#10B981/gi;
    s/#F4893A/#FBBF24/gi; s/#DE7341/#F59E0B/gi; s/#f36700/#F59E0B/gi;
    s/#F36653/#F0716A/gi; s/#D2402D/#E7564E/gi; s/#e54d39/#E7564E/gi;
  ' "$f"
done

# Entry-page <title> tags (never rendered inside the CEF start page, but keep
# the shipped tree clean of the upstream product name).
perl -pi -e 's/<title>[^<]*ONLYOFFICE[^<]*<\/title>/<title>Scrivar Office<\/title>/' src/index.html
perl -pi -e 's/<title>[^<]*ONLYOFFICE[^<]*<\/title>/<title>Scrivar Office error<\/title>/' noconnect/index.html

echo "Loginpage locale sweep done. Remaining ONLYOFFICE in translatable strings:"
(grep -o "wel[A-Za-z]*: *'[^']*ONLYOFFICE[^']*'" locale/*.js src/locale.js || true) | wc -l | xargs echo "  welcome-key hits left:"
(grep -o "ONLYOFFICE Cloud Service\|Connect to cloud" locale/*.js src/locale.js || true) | wc -l | xargs echo "  cloud-identity hits left (must be 0):"
# Full residual audit — expected leftovers are ONLY the AGPL "Based on
# ONLYOFFICE" credit in panelabout.js and the commented example in sdk.js.
echo "  full residual list (locale values only should be empty):"
grep -rn "ONLYOFFICE" locale/ src/locale.js || echo "    (clean)"
