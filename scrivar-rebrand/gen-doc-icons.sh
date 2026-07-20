#!/bin/bash
# Scrivar Office rebrand — 46 Finder document-type icons (P1).
# Regenerates macos/ONLYOFFICE/Resources/file-formats/*.icns with the Scrivar
# page+mark system: white page + folded corner + format pill, colored by
# editor family (ROADMAP Decision log):
#   Document #4F46E5 / Spreadsheet #10B981 / Presentation #F59E0B /
#   PDF #E7564E / Diagram keeps upstream slate #444796
# Small indigo squircle-S = the Scrivar mark, constant across families.
# Requires: rsvg-convert (brew librsvg), iconutil (macOS).
# Idempotent; re-run after any upstream rebase that touches file-formats/.
set -euo pipefail

FORMATS_DIR="$(cd "$(dirname "$0")/../macos/ONLYOFFICE/Resources/file-formats" && pwd)"
WORK="$(mktemp -d)"
trap 'rm -rf "$WORK"' EXIT

INDIGO="#4F46E5"; GREEN="#10B981"; AMBER="#F59E0B"; CORAL="#E7564E"; SLATE="#444796"

family_color() {
  case "$1" in
    doc|docx|dotx|odt|ott|fodt|rtf|txt|epub|fb2|htm|html|mht|xml|hwp|hwpx|pages|md) echo "$INDIGO" ;;
    csv|ods|ots|fods|xls|xlsb|xlsm|xlsx|xltx|numbers) echo "$GREEN" ;;
    odp|otp|pot|potx|pps|ppsx|ppt|pptm|pptx|key) echo "$AMBER" ;;
    pdf|djvu|oform|docxf|xps|oxps) echo "$CORAL" ;;
    vsdx|odg) echo "$SLATE" ;;
    *) echo "$INDIGO" ;;
  esac
}

make_svg() { # $1=label $2=color $3=outfile
  local label; label="$(echo "$1" | tr '[:lower:]' '[:upper:]')"
  local color="$2" out="$3"
  local len=${#label} fs pillw
  if   [ "$len" -le 3 ]; then fs=128
  elif [ "$len" -le 4 ]; then fs=112
  elif [ "$len" -le 5 ]; then fs=96
  elif [ "$len" -le 6 ]; then fs=84
  else fs=72; fi
  pillw=$(( len * fs * 62 / 100 + 120 ))
  [ "$pillw" -gt 580 ] && pillw=580
  local pillx=$(( 512 - pillw / 2 ))
  cat > "$out" <<SVG
<svg width="1024" height="1024" viewBox="0 0 1024 1024" xmlns="http://www.w3.org/2000/svg">
  <!-- page with cut top-right corner -->
  <path d="M240 96 H672 L832 256 V880 Q832 928 784 928 H240 Q192 928 192 880 V144 Q192 96 240 96 Z"
        fill="#FFFFFF" stroke="#D5D9E0" stroke-width="10"/>
  <!-- folded corner flap -->
  <path d="M672 96 L832 256 H672 Z" fill="$color"/>
  <!-- Scrivar mark -->
  <rect x="264" y="176" width="120" height="120" rx="28" fill="$INDIGO"/>
  <text x="324" y="264" font-family="Helvetica,Arial,sans-serif" font-weight="700" font-size="86"
        fill="#FFFFFF" text-anchor="middle">S</text>
  <!-- content lines -->
  <rect x="264" y="420" width="496" height="36" rx="18" fill="#E5E7EB"/>
  <rect x="264" y="496" width="496" height="36" rx="18" fill="#E5E7EB"/>
  <rect x="264" y="572" width="360" height="36" rx="18" fill="#E5E7EB"/>
  <!-- format pill -->
  <rect x="$pillx" y="680" width="$pillw" height="150" rx="42" fill="$color"/>
  <text x="512" y="$(( 680 + 75 + fs * 35 / 100 ))" font-family="Helvetica,Arial,sans-serif" font-weight="700"
        font-size="$fs" fill="#FFFFFF" text-anchor="middle" letter-spacing="2">$label</text>
</svg>
SVG
}

render_icns() { # $1=svg $2=icns-out $3=name
  local svg="$1" icns="$2" name="$3"
  local iconset="$WORK/$name.iconset"
  mkdir -p "$iconset"
  for s in 16 32 128 256 512; do
    rsvg-convert -w $s -h $s "$svg" -o "$iconset/icon_${s}x${s}.png"
    rsvg-convert -w $((s*2)) -h $((s*2)) "$svg" -o "$iconset/icon_${s}x${s}@2x.png"
  done
  iconutil -c icns "$iconset" -o "$icns"
}

count=0
for f in "$FORMATS_DIR"/*.icns; do
  base="$(basename "$f" .icns)"          # file-docx | md
  ext="${base#file-}"                    # docx | md
  color="$(family_color "$ext")"
  make_svg "$ext" "$color" "$WORK/$base.svg"
  render_icns "$WORK/$base.svg" "$f" "$base"
  count=$((count+1))
done
echo "Regenerated $count .icns in $FORMATS_DIR"
