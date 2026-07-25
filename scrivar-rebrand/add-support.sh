#!/bin/bash
# Scrivar Office rebrand — add a "Help & contact" entry to the start-page rail.
#
# Scrivar Office's in-app support form (launcher v1.0.7) had no discoverable
# entry point inside the suite: a customer could only reach it by opening
# Scrivar Office a SECOND time while it was already running, which surfaces the
# licence window. Scrivar PDF has a persistent "Contact us" button; this brings
# Office to parity. The rail item sits below "Cloud & AI" and above "Settings",
# and its click opens the resident launcher's support form
# (scrivar-office://support → main.js isSupportDeepLink → openWindow('support')).
#
# AGPL note: the fork carries ONLY the literal scrivar-office://support URL and
# a window.open — zero Scrivar account/ticket/token logic, and no support
# endpoint URL. CEF routes the custom scheme to the OS → LaunchServices → the
# launcher (which owns scrivar-office:// and is resident whenever the suite
# runs). Identical "mere aggregation" signalling to add-cloud-ai.sh.
#
# Icon: reuses the existing "#about" sprite (an info glyph). It is otherwise
# referenced only by the upstream about item, which ships hidden — so no new
# asset is needed and nothing else changes appearance.
#
# Run order: independent of the other loginpage sweeps (all idempotent). Rebuild
# the loginpage (grunt in common/loginpage/build) after — NO C++ rebuild needed.
set -euo pipefail
cd "$(dirname "$0")/../common/loginpage"

# --- 1. panels.js: rail <li> above Settings + click → launcher support form ---
python3 - <<'PY'
p = 'src/panels.js'
s = open(p).read()
if 'SCRIVAR-REBRAND: Help & contact rail' in s:
    print('panels.js: already patched')
else:
    # (a) insert the rail item immediately before the Settings <li>. When
    #     add-cloud-ai.sh has already run, this lands directly beneath it.
    settings_anchor = (
        "              <li class=\"menu-item\">\n"
        "                  <a action=\"settings\">\n"
    )
    if settings_anchor not in s:
        raise SystemExit('ERROR: panels.js Settings <li> anchor not found')
    rail_item = (
        "              <!-- SCRIVAR-REBRAND: Help & contact rail entry (opens the launcher support form via scrivar-office://support) -->\n"
        "              <li class=\"menu-item\">\n"
        "                <a action=\"custom-support\">\n"
        "                    <div class=\"icon-box\">\n"
        "                        <svg class=\"icon\" data-iconname=\"about\" data-precls=\"tool-icon\">\n"
        "                            <use href=\"#about\"></use>\n"
        "                        </svg>\n"
        "                    </div>\n"
        "                    <span class=\"text\" l10n>${utils.Lang.actHelpContact}</span>\n"
        "                </a>\n"
        "              </li>\n"
    )
    s = s.replace(settings_anchor, rail_item + settings_anchor, 1)

    # (b) bind the click right after the rail's delegated click registration.
    #     action="custom-*" makes onActionClick early-return (panels.js), so no
    #     panel machinery runs — we just open the launcher.
    click_anchor = "    $('.tool-menu').on('click', '> .menu-item > a', onActionClick);\n"
    if click_anchor not in s:
        raise SystemExit('ERROR: panels.js tool-menu click-registration anchor not found')
    click_bind = (
        "    /* SCRIVAR-REBRAND: Help & contact rail — open the resident launcher's support\n"
        "       form. window.open on a custom scheme is intercepted by CEF and handed to the\n"
        "       OS (LaunchServices) → the scrivar-office:// handler (the launcher). No\n"
        "       account/ticket/endpoint logic in the fork — just this URL. */\n"
        "    $('.tool-menu').on('click', '> .menu-item > a[action=\"custom-support\"]', function(e) {\n"
        "        e.preventDefault();\n"
        "        window.open('scrivar-office://support');\n"
        "    });\n"
    )
    s = s.replace(click_anchor, click_anchor + click_bind, 1)
    open(p, 'w').write(s)
    print('panels.js: Help & contact rail entry + click handler added')
PY
grep -q 'SCRIVAR-REBRAND: Help & contact rail' src/panels.js || { echo "ERROR: panels.js patch failed"; exit 1; }

# --- 2. locale.js: the rail label --------------------------------------------
python3 - <<'PY'
p = 'src/locale.js'
s = open(p).read()
if 'actHelpContact' in s:
    print('locale.js: already has actHelpContact')
else:
    anchor = "    actSettings: 'Settings',\n"
    if anchor not in s:
        raise SystemExit('ERROR: locale.js actSettings anchor not found')
    s = s.replace(anchor, anchor + "    actHelpContact: 'Help & contact', /* SCRIVAR-REBRAND */\n", 1)
    open(p, 'w').write(s)
    print('locale.js: actHelpContact added')
PY
grep -q 'actHelpContact' src/locale.js || { echo "ERROR: locale.js patch failed"; exit 1; }

echo "add-support done:"
echo "  panels.js rail entry:  $(grep -c 'custom-support' src/panels.js) reference(s) (markup + click)"
echo "  locale.js label:       $(grep -c 'actHelpContact' src/locale.js)"
