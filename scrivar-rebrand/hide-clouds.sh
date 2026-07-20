#!/bin/bash
# Scrivar Office rebrand — hide the Clouds/portal-connect surface (P3).
# Scrivar Office ships no cloud portal providers: Scrivar Cloud is a
# launcher-side sync folder (private, mere aggregation), so the loginpage
# "Clouds" sidebar tab + connect adverts must never show and the bundled
# ONLYOFFICE/third-party portal provider configs are stripped.
#
# Run order: run AFTER sweep-loginpage.sh (either order works — both are
# idempotent — but keep sweeps first by convention), then rebuild the
# loginpage (grunt in common/loginpage/build) and redeploy index.html.
#
# What it does (all idempotent):
#   1. src/panels.js — the upstream "no cloud providers" check only tests
#      falsy, but utils.fn.sortProviders() returns [] (truthy) for an empty
#      provider list, so the Clouds tab survived with zero providers.
#      Patch the check to treat an EMPTY checklist as "no providers".
#   2. src/panelwelcome.js — hide the .tools-connect cloud advert block
#      (create-portal / connect links) in the welcome panel.
#   3. providers/ — remove every bundled provider config dir (box, dropbox,
#      kdrive, liferay, moodle, nextcloud, onlyoffice, owncloud, seafile);
#      keep the directory itself (.gitkeep) so deploy_desktop.py's
#      copy_dir(providers) step keeps working unmodified.
set -euo pipefail
cd "$(dirname "$0")/../common/loginpage"

# --- 1. panels.js: empty checklist == no providers -------------------------
if ! grep -q 'portals.checklist.length' src/panels.js; then
  perl -pi -e 's/if \(!window\.config\.portals\.checklist\) \{/if (!window.config.portals.checklist || !window.config.portals.checklist.length) { \/* SCRIVAR-REBRAND (P3): sortProviders() returns [] (truthy) — an EMPTY provider checklist must hide the Clouds surface too *\//' src/panels.js
fi
grep -q 'portals.checklist.length' src/panels.js || { echo "ERROR: panels.js patch failed"; exit 1; }

# --- 2. panelwelcome.js: hide the cloud-connect advert ---------------------
python3 - <<'PY'
import re
p = 'src/panelwelcome.js'
s = open(p).read()
if 'SCRIVAR-REBRAND' not in s:
    m = re.search(r'\n([ \t]+)this\.view\.render\(\);', s)
    if not m:
        raise SystemExit('ERROR: panelwelcome.js anchor (this.view.render();) not found')
    ind = m.group(1)
    ins = (m.group(0)
           + '\n\n' + ind + '/* SCRIVAR-REBRAND (P3): Scrivar Office has no cloud portals — hide the cloud-connect advert */'
           + '\n' + ind + "$('.tools-connect', this.view.$panel).hide();")
    s = s[:m.start()] + ins + s[m.end():]
    open(p, 'w').write(s)
PY
grep -q 'SCRIVAR-REBRAND' src/panelwelcome.js || { echo "ERROR: panelwelcome.js patch failed"; exit 1; }

# --- 3. providers/: strip bundled portal provider configs ------------------
if compgen -G 'providers/*/' > /dev/null; then
  rm -rf providers/*/
fi
touch providers/.gitkeep

echo "hide-clouds done:"
echo "  panels.js checklist check: $(grep -c 'portals.checklist.length' src/panels.js) patch line(s)"
echo "  panelwelcome advert hide:  $(grep -c 'tools-connect' src/panelwelcome.js) reference(s) (template + hide)"
echo "  provider config dirs left: $(find providers -name config.json | wc -l | tr -d ' ')"
