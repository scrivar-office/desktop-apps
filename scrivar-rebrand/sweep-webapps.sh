#!/bin/bash
# Scrivar Office rebrand — web-apps (in-editor) sweep.
#
# Covers the MECHANICAL part of the in-editor rebrand (P1):
#   1) Per-editor accent retint to the Scrivar palette (ROADMAP Decision log):
#        Document    #446995 -> #4F46E5   (text-on-bg #38567A -> #3730A3)
#        Spreadsheet #3A8056 -> #10B981   (text-on-bg #336B49 -> #047857)
#                    #40865C -> #10B981   (mobile/legacy alt of the same green)
#        Presentation#B75B44 -> #F59E0B   (text-on-bg #854535 -> #B45309)
#                    #BE664F -> #F59E0B   (reporter/legacy alt)
#        PDF/Forms   #AA5252 -> #E7564E   (text-on-bg #8D4444 -> #C03C35)
#        Visio keeps upstream #444796 (not one of our five editors).
#      Applied to the theme color tables, editor skeleton-loader fallbacks and
#      the sse toolbar legacy variable.
#   2) Splash loader-dot colors -> Scrivar triad (indigo/green/amber).
#   3) Product name in editor <title> tags (ONLYOFFICE -> Scrivar Office).
#   4) Gruntfile.js build-time brand defaults (publisher, support/help URLs).
#   5) onlyoffice.com hrefs in editor HTML -> scrivar.com.
#
# NOT covered here (git-tracked direct edits with SCRIVAR-REBRAND markers):
#   About.js publisher rows + AGPL credit, about/header logo SVGs.
#
# Idempotent; re-run after every upstream rebase of the web-apps fork, then
# rebuild the editors payload (build_js). Legal notices in file headers
# (Ascensio copyright) are NOT touched.
set -euo pipefail
cd "$(dirname "$0")/../../web-apps"

echo "[1/5] accent retint (theme tables + skeleton fallbacks)"
retint() {
  perl -pi -e '
    s/#446995/#4F46E5/gi; s/#38567A/#3730A3/gi;
    s/#3A8056/#10B981/gi; s/#336B49/#047857/gi; s/#40865C/#10B981/gi;
    s/#B75B44/#F59E0B/gi; s/#854535/#B45309/gi; s/#BE664F/#F59E0B/gi;
    s/#AA5252/#E7564E/gi; s/#8D4444/#C03C35/gi;
  ' "$1"
}
for f in apps/common/main/resources/less/colors-table*.less \
         apps/*/main/index*.html \
         apps/spreadsheeteditor/main/resources/less/toolbar.less; do
  retint "$f"
done

echo "[2/5] splash loader dots -> Scrivar triad"
for f in apps/*/main/index_loader.html; do
  perl -pi -e 's/#55bce6/#4F46E5/gi; s/#a1cb5c/#10B981/gi; s/#de7a59/#F59E0B/gi;' "$f"
done

echo "[3/5] <title> product-name sweep"
for f in apps/*/main/index*.html apps/*/forms/index*.html; do
  [ -f "$f" ] || continue
  perl -pi -e '
    s/<title>([^<]*)ONLYOFFICE Documents([^<]*)<\/title>/<title>${1}Scrivar Office$2<\/title>/;
    s/<title>([^<]*)ONLYOFFICE([^<]*)<\/title>/<title>${1}Scrivar Office$2<\/title>/;
  ' "$f"
done

echo "[4/5] Gruntfile.js brand defaults"
perl -pi -e "
  s/(process\.env\.SUPPORT_EMAIL\) \|\| )'support\@onlyoffice\.com'/\$1'jeremiah\@scrivar.com'/;
  s/(process\.env\.SUPPORT_URL\) \|\| )'https:\/\/support\.onlyoffice\.com'/\$1'https:\/\/scrivar.com\/support'/;
  s/(process\.env\.SALES_EMAIL\) \|\| )'sales\@onlyoffice\.com'/\$1'jeremiah\@scrivar.com'/;
  s/(process\.env\.PUBLISHER_URL\) \|\| )'https:\/\/www\.onlyoffice\.com'/\$1'https:\/\/www.scrivar.com'/;
  s/(process\.env\['PUBLISHER_PHONE'\] \|\| )'\+371 633-99867'/\$1''/;
  s/(process\.env\.PUBLISHER_NAME\) \|\| )'Ascensio System SIA'/\$1'Scrivar Inc.'/;
  s/(process\.env\.PUBLISHER_ADDRESS\) \|\| )'20A-12 Ernesta Birznieka-Upisha street, Riga, Latvia, EU, LV-1050'/\$1''/;
  s/(process\.env\.COMPANY_NAME\) \|\| )'ONLYOFFICE'/\$1'Scrivar'/;
  s/(process\.env\.APP_TITLE_TEXT\) \|\| )'ONLYOFFICE'/\$1'Scrivar Office'/;
  s/(process\.env\.HELP_URL\) \|\| )'https:\/\/helpcenter\.onlyoffice\.com'/\$1'https:\/\/scrivar.com\/support'/;
  s/(\|\| )'https:\/\/helpcenter\.onlyoffice\.com\/userguides\/docs-(de|se|pe)\.aspx'/\$1'https:\/\/scrivar.com\/support'/;
  s/(process\.env\.SUGGEST_URL\) \|\| )'https:\/\/feedback\.onlyoffice\.com[^']*'/\$1'https:\/\/scrivar.com\/support'/;
  s/(process\.env\['APP_CUSTOMER_NAME'\] \|\| )'ONLYOFFICE'/\$1'Scrivar'/;
" build/Gruntfile.js

echo "[5/5] onlyoffice.com hrefs in editor html"
for f in apps/*/main/index*.html apps/*/forms/index*.html; do
  [ -f "$f" ] || continue
  perl -pi -e 's/(href=")https?:\/\/(www\.)?onlyoffice\.com\/?(")/${1}https:\/\/www.scrivar.com\/$3/g' "$f"
done

echo "Done. Remaining ONLYOFFICE brand hits in visible surfaces:"
grep -rn 'ONLYOFFICE' apps/*/main/index*.html build/Gruntfile.js 2>/dev/null | grep -v 'Copyright\|copyright\|@onlyoffice.com in the header' | head -10 || true
echo "Old accent hexes left (expect none outside visio #444796):"
grep -rniE '#(446995|3A8056|B75B44|AA5252|40865C|BE664F|38567A|336B49|854535|8D4444)' \
  apps/common/main/resources/less/colors-table*.less apps/*/main/index*.html 2>/dev/null | head -5 || true
