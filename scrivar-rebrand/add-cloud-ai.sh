#!/bin/bash
# Scrivar Office rebrand — add a "Cloud & AI" entry to the start-page rail.
#
# Scrivar Cloud & AI (sync + AI, a paid add-on) had NO discoverable entry point
# inside the suite — subscribe/manage lived only in the launcher's window,
# reachable only by relaunching the app. This adds a "Cloud & AI" item to the
# start-page (loginpage) left rail, above "Settings", whose click opens the
# resident launcher's manage window (subscription status + Subscribe / Manage;
# cancel lives in the Stripe portal there).
#
# AGPL note: the fork carries ONLY the literal scrivar-office://manage URL and a
# window.open — zero Scrivar account/token/billing logic. CEF routes the custom
# scheme to the OS → LaunchServices → the launcher (which owns scrivar-office://
# and is resident whenever the suite runs). "Mere aggregation" signaling, same
# spirit as the launcher-side Scrivar Cloud folder.
#
# Run order: independent of the other loginpage sweeps (all idempotent). Rebuild
# the loginpage (grunt in common/loginpage/build) after — the OO_ONLY_BUILD_JS=1
# loop suffices; NO C++ rebuild needed. Same flow as hide-ai-agent.sh.
set -euo pipefail
cd "$(dirname "$0")/../common/loginpage"

# --- 1. panels.js: rail <li> above Settings + click → launcher manage window --
python3 - <<'PY'
p = 'src/panels.js'
s = open(p).read()
if 'SCRIVAR-REBRAND: Cloud & AI rail' in s:
    print('panels.js: already patched')
else:
    # (a) insert the rail item immediately before the Settings <li>.
    settings_anchor = (
        "              <li class=\"menu-item\">\n"
        "                  <a action=\"settings\">\n"
    )
    if settings_anchor not in s:
        raise SystemExit('ERROR: panels.js Settings <li> anchor not found')
    rail_item = (
        "              <!-- SCRIVAR-REBRAND: Cloud & AI rail entry (opens the launcher manage window via scrivar-office://manage) -->\n"
        "              <li class=\"menu-item\">\n"
        "                <a action=\"custom-cloudai\">\n"
        "                    <div class=\"icon-box\">\n"
        "                        <svg class=\"icon\" data-iconname=\"aichat\" data-precls=\"tool-icon\">\n"
        "                            <use href=\"#aichat\"></use>\n"
        "                        </svg>\n"
        "                    </div>\n"
        "                    <span class=\"text\" l10n>${utils.Lang.actCloudAI}</span>\n"
        "                </a>\n"
        "              </li>\n"
    )
    s = s.replace(settings_anchor, rail_item + settings_anchor, 1)

    # (b) bind the click right after the rail's delegated click registration.
    #     action="custom-*" makes onActionClick early-return (panels.js:203), so
    #     no panel machinery runs — we just open the launcher.
    click_anchor = "    $('.tool-menu').on('click', '> .menu-item > a', onActionClick);\n"
    if click_anchor not in s:
        raise SystemExit('ERROR: panels.js tool-menu click-registration anchor not found')
    click_bind = (
        "    /* SCRIVAR-REBRAND: Cloud & AI rail — open the resident launcher's manage window.\n"
        "       window.open on a custom scheme is intercepted by CEF and handed to the OS\n"
        "       (LaunchServices) → the scrivar-office:// handler (the launcher). No account/\n"
        "       token/billing logic in the fork — just this URL. */\n"
        "    $('.tool-menu').on('click', '> .menu-item > a[action=\"custom-cloudai\"]', function(e) {\n"
        "        e.preventDefault();\n"
        "        window.open('scrivar-office://manage');\n"
        "    });\n"
    )
    s = s.replace(click_anchor, click_anchor + click_bind, 1)
    open(p, 'w').write(s)
    print('panels.js: Cloud & AI rail entry + click handler added')
PY
grep -q 'SCRIVAR-REBRAND: Cloud & AI rail' src/panels.js || { echo "ERROR: panels.js patch failed"; exit 1; }

# --- 2. locale.js: the rail label -------------------------------------------
python3 - <<'PY'
p = 'src/locale.js'
s = open(p).read()
if 'actCloudAI' in s:
    print('locale.js: already has actCloudAI')
else:
    anchor = "    actSettings: 'Settings',\n"
    if anchor not in s:
        raise SystemExit('ERROR: locale.js actSettings anchor not found')
    s = s.replace(anchor, anchor + "    actCloudAI: 'Cloud & AI', /* SCRIVAR-REBRAND */\n", 1)
    open(p, 'w').write(s)
    print('locale.js: actCloudAI added')
PY
grep -q 'actCloudAI' src/locale.js || { echo "ERROR: locale.js patch failed"; exit 1; }

echo "add-cloud-ai done:"
echo "  panels.js rail entry:  $(grep -c 'custom-cloudai' src/panels.js) reference(s) (markup + click)"
echo "  locale.js label:       $(grep -c 'actCloudAI' src/locale.js)"
