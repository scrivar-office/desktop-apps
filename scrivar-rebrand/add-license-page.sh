#!/bin/bash
# Scrivar Office rebrand — ship the in-app License Agreement page (macOS).
#
# BUG: Help > License Agreement (and the About dialog's License button) call
# openEULA, which loads Contents/Resources/license/EULA.html from the bundle.
# The mac pbxproj already copies a `Vendor/ONLYOFFICE/license` folder into the
# bundle AND the "Copy application resources" Run Script mkdir's that folder —
# but nothing ever PUTS an EULA/LICENSE file in it, so it ships EMPTY and both
# entry points silently do nothing.
#
# FIX (all idempotent):
#   1. Generate ONLYOFFICE/Resources/EULA.html — a self-contained Scrivar Office
#      license page: "based on ONLYOFFICE, modified, AGPLv3" notice + source
#      links + the full AGPL v3 text (from desktop-apps/LICENSE). This also
#      strengthens AGPL compliance (the license is readable in-app, offline).
#   2. Patch BOTH "Copy application resources" Run Script phases in the pbxproj
#      to copy EULA.html into ${DST_DIR}/license/ right after they mkdir it, so
#      Stage-2 seals it into the signed bundle.
#
# Rebuild: Stage-2 only (xcodebuild) — no engine recompile. Re-run after any
# desktop-apps rebase.
set -euo pipefail
cd "$(dirname "$0")/.."   # desktop-apps

LICENSE_SRC="LICENSE"
EULA_OUT="macos/ONLYOFFICE/Resources/EULA.html"

[ -f "$LICENSE_SRC" ] || { echo "ERROR: $LICENSE_SRC (AGPL text) not found"; exit 1; }

# --- 1. generate EULA.html --------------------------------------------------
python3 - "$LICENSE_SRC" "$EULA_OUT" <<'PY'
import sys, html
license_path, out_path = sys.argv[1], sys.argv[2]
agpl = html.escape(open(license_path, encoding='utf-8').read())
doc = """<!DOCTYPE html>
<html lang="en">
<head>
<meta charset="utf-8" />
<meta name="viewport" content="width=device-width, initial-scale=1.0" />
<title>Scrivar Office — License Agreement</title>
<style>
  body { font: 13px/1.55 -apple-system, "Helvetica Neue", Arial, sans-serif; color:#1b1b1f; margin:0; padding:28px 34px; background:#fff; }
  h1 { font-size:20px; margin:0 0 6px; }
  .lede { color:#3a3a45; margin:0 0 14px; }
  a { color:#4F46E5; }
  hr { border:0; border-top:1px solid #e6e6ec; margin:18px 0; }
  h2 { font-size:13px; letter-spacing:.04em; text-transform:uppercase; color:#6b6b76; margin:0 0 10px; }
  pre { white-space:pre-wrap; word-wrap:break-word; font:12px/1.5 "SF Mono", ui-monospace, Menlo, monospace; color:#26262c; margin:0; }
</style>
</head>
<body>
<h1>Scrivar Office — License Agreement</h1>
<p class="lede">Scrivar Office is based on <b>ONLYOFFICE&reg; Desktop Editors</b> and has been modified by Scrivar Inc. It is free software, licensed under the <b>GNU Affero General Public License, version 3 (AGPLv3)</b>. There is no additional end-user restriction — your rights are those the AGPL grants.</p>
<p class="lede">Complete corresponding source code for this build is published at <a href="https://github.com/scrivar-office">github.com/scrivar-office</a>. The upstream project is ONLYOFFICE (<a href="https://github.com/ONLYOFFICE">github.com/ONLYOFFICE</a>). Trademarks are the property of their respective owners; no trademark rights are granted under this license.</p>
<hr />
<h2>GNU Affero General Public License v3</h2>
<pre>%s</pre>
</body>
</html>
""" % agpl
open(out_path, 'w', encoding='utf-8').write(doc)
print("EULA.html generated (%d bytes)" % len(doc))
PY
[ -s "$EULA_OUT" ] || { echo "ERROR: EULA.html not generated"; exit 1; }

# --- 2. patch the pbxproj Run Script phases (both arm + x64) -----------------
python3 - <<'PY'
p = 'macos/ONLYOFFICE.xcodeproj/project.pbxproj'
s = open(p).read()
if 'SCRIVAR-REBRAND: ship the in-app License' in s:
    print('pbxproj: already copies EULA.html')
else:
    # In each "Copy application resources" Run Script, the license dir is
    # created by this exact (escaped) line — append a cp right after it.
    anchor = '[ ! -d \\"${DST_DIR}/license\\" ] && mkdir -p \\"${DST_DIR}/license\\"\\n'
    n = s.count(anchor)
    if n == 0:
        raise SystemExit('ERROR: pbxproj license-mkdir anchor not found')
    add = ('# SCRIVAR-REBRAND: ship the in-app License Agreement page (empty upstream)\\n'
           'cp -vR \\"${BASE_DIR}/ONLYOFFICE/Resources/EULA.html\\" \\"${DST_DIR}/license/EULA.html\\"\\n')
    s = s.replace(anchor, anchor + add)
    open(p, 'w').write(s)
    print('pbxproj: EULA.html copy added to %d Run Script phase(s)' % n)
PY
grep -c 'SCRIVAR-REBRAND: ship the in-app License' macos/ONLYOFFICE.xcodeproj/project.pbxproj \
  | xargs echo "pbxproj EULA copy phases patched (arm/x64/v8):"

echo "add-license-page done."
