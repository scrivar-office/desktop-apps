#!/bin/bash
# Scrivar Office rebrand — hide the start-page "AI agent" tab (P4/AI-lockdown).
#
# The upstream 9.x "AI agent" is a SEPARATE bundled React/Vite desktop plugin
# (GUID 9DC93CDB-B576-4F0C-B55E-FCC9C48DD777, distinct from the in-editor "AI"
# plugin ...DD007 that patch-ai-plugin.sh seeds with Scrivar AI). It surfaces
# as a start-page (loginpage) sidebar tab whose Settings > Connection pane lets
# a user wire ARBITRARY providers (Anthropic/OpenAI/... + API key), plus MCP
# Servers and Web Search — none of which route through Scrivar Cloud & AI.
# Scrivar Office ships Scrivar Cloud & AI as the ONLY AI surface, so this tab
# must never appear.
#
# Mechanism: at start-page load the desktop SDK fires a per-plugin
# "panel:external" native message; panelexternal.js _add_custom_panel(opts)
# builds BOTH the sidebar <li> and the iframe panel for each external plugin
# (the AI agent GUID is already special-cased there for its #aichat icon). The
# C++ disable-ai=1 path does NOT suppress this (it only filters the in-editor
# plugin list), so the hide lives in the loginpage JS — the direct analog of
# hide-clouds.sh. A marker-guarded early return at the top of _add_custom_panel
# removes the tab, its iframe panel, and the ?panel= deep-link route in one shot.
#
# Run order: independent of the other loginpage sweeps (all idempotent); by
# convention run the sweeps first, then rebuild the loginpage (grunt in
# common/loginpage/build) so deploy/index.html is regenerated and redeployed.
# The Stage-1 JS build (build_js.py build_interface) does this rebuild; the
# OO_ONLY_BUILD_JS=1 loop is sufficient — no C++ rebuild is needed for this hide.
set -euo pipefail
cd "$(dirname "$0")/../common/loginpage"

AI_AGENT_GUID='9DC93CDB-B576-4F0C-B55E-FCC9C48DD777'

python3 - "$AI_AGENT_GUID" <<'PY'
import sys
guid = sys.argv[1]
p = 'src/panelexternal.js'
s = open(p).read()
if 'SCRIVAR-REBRAND: hide AI agent' in s:
    print('panelexternal.js: already patched')
    sys.exit(0)

anchor = "        function _add_custom_panel(opts) {\n" \
         "            let item_name = opts.name,\n" \
         "                panel_url = opts.url,\n" \
         "                panel_id = opts.id;\n"
if anchor not in s:
    raise SystemExit('ERROR: panelexternal.js anchor (_add_custom_panel opts destructure) not found')

guard = (
    "\n"
    "            /* SCRIVAR-REBRAND: hide AI agent — Scrivar Cloud & AI is the only AI\n"
    "               surface; suppress the upstream start-page 'AI agent' plugin tab\n"
    "               (raw provider/MCP/web-search wiring). Skipping here removes the\n"
    "               sidebar item, its iframe panel, and the ?panel= deep-link route. */\n"
    "            if ( panel_id && panel_id.indexOf('" + guid + "') !== -1 )\n"
    "                return;\n"
)
s = s.replace(anchor, anchor + guard, 1)
open(p, 'w').write(s)
print('panelexternal.js: AI agent hide added')
PY

grep -q 'SCRIVAR-REBRAND: hide AI agent' src/panelexternal.js || { echo "ERROR: panelexternal.js patch failed"; exit 1; }

echo "hide-ai-agent done:"
echo "  panelexternal.js guard: $(grep -c "$AI_AGENT_GUID" src/panelexternal.js) GUID reference(s) (icon special-case + hide guard)"
