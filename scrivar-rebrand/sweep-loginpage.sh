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
  # Remaining standalone product-name mentions in translatable STRING VALUES.
  # Restrict to the l10n string keys so we never rewrite code identifiers or
  # the info@onlyoffice.com contact in the header comment.
  perl -0pi -e "s/(wel\w+|text\w+|btn\w+|link\w+|portal\w+|login\w+|empty\w+):(\s*)'([^']*?)ONLYOFFICE([^']*?)'/\$1:\$2'\$3Scrivar Office\$4'/g" "$1"
}

for f in locale/*.js src/locale.js; do sweep "$f"; done

echo "Loginpage locale sweep done. Remaining ONLYOFFICE in translatable strings:"
grep -o "wel[A-Za-z]*: *'[^']*ONLYOFFICE[^']*'" locale/*.js src/locale.js | wc -l | xargs echo "  welcome-key hits left:"
