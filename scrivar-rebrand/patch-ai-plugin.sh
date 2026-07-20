#!/bin/bash
# Scrivar Office rebrand — AI plugin preinstall loader (P3).
# Patches the bundled ONLYOFFICE AI plugin (onlyoffice.github.io checkout,
# a SIBLING of desktop-apps — sdkjs-plugins/content/ai, v3.2.3) so that on
# FIRST RUN (empty/absent plugin localStorage) it seeds one provider,
# "Scrivar AI" -> http://127.0.0.1:41317/v1 (the launcher's local
# OpenAI-compatible proxy; NO remote URLs, NO secrets — the plugin already
# whitelists 127.0.0.1 via AI.isLocalUrl), with model id 'scrivar-ai' as
# the default for the text actions (Chat/Summarization/Translation/
# TextAnalyze). Upstream ships preinstall-example.json but NOTHING loads
# it in 3.2.3 — this adds the loader upstream forgot.
#
# Run order: independent of the loginpage sweeps; re-run after any
# onlyoffice.github.io upstream rebase, then re-deploy the plugin (full
# deploy driver, or copy the plugin dir into
# out/.../desktopeditors/editors/sdkjs-plugins/{9DC93CDB-B576-4F0C-B55E-FCC9C48DD007}/).
# Idempotent: marker-guarded edits + unconditional preinstall.json rewrite.
set -euo pipefail
cd "$(dirname "$0")/../../onlyoffice.github.io/sdkjs-plugins/content/ai"

# --- 1. engine: AI.Storage.preinstall() ------------------------------------
python3 - <<'PY'
p = 'scripts/engine/local_storage.js'
s = open(p).read()
if 'SCRIVAR-REBRAND' not in s:
    anchor = "\tAI.Storage.addModel = function(model) {"
    if anchor not in s:
        raise SystemExit('ERROR: local_storage.js anchor (AI.Storage.addModel) not found')
    patch = """\t// SCRIVAR-REBRAND begin (P3): preinstall loader.
\t// On a first run with empty/absent plugin storage, seed providers/models
\t// and default action models from ./preinstall.json shipped at the plugin
\t// root (same schema as scripts/engine/providers/preinstall-example.json,
\t// which upstream 3.2.3 ships but never loads). Runs once, BEFORE the
\t// regular loadInternalProviders()/Storage.load() pipeline, so the
\t// synchronous timing of AI.Storage.load() is unchanged.
\tAI.Storage.preinstall = async function() {
\t\ttry {
\t\t\tif (AI.serverSettings)
\t\t\t\treturn;

\t\t\tlet existing = null;
\t\t\ttry {
\t\t\t\texisting = JSON.parse(window.localStorage.getItem(localStorageKey));
\t\t\t} catch (e) {
\t\t\t}
\t\t\tif (existing && existing.version === AI.Storage.Version)
\t\t\t\treturn;

\t\t\tlet text = await AI.loadResourceAsText("./preinstall.json");
\t\t\tif (!text)
\t\t\t\treturn;

\t\t\tlet pre = JSON.parse(text);
\t\t\tif (!pre || !pre.providers)
\t\t\t\treturn;

\t\t\twindow.localStorage.setItem(localStorageKey, JSON.stringify({
\t\t\t\tversion : AI.Storage.Version,
\t\t\t\tproviders : pre.providers,
\t\t\t\tmodels : pre.models || [],
\t\t\t\tcustomProviders : pre.customProviders || {}
\t\t\t}));

\t\t\t// Default models for actions — only fill actions that are unset,
\t\t\t// so a model already picked by the user/desktop always wins.
\t\t\tif (pre.actions && AI.Actions) {
\t\t\t\tlet changed = false;
\t\t\t\tfor (let type in pre.actions) {
\t\t\t\t\tif (AI.Actions[type] && pre.actions[type].model && !AI.Actions[type].model) {
\t\t\t\t\t\tAI.Actions[type].model = pre.actions[type].model;
\t\t\t\t\t\tchanged = true;
\t\t\t\t\t}
\t\t\t\t}
\t\t\t\tif (changed && AI.ActionsSave)
\t\t\t\t\tAI.ActionsSave();
\t\t\t}
\t\t} catch (e) {
\t\t}
\t};
\t// SCRIVAR-REBRAND end (P3)

"""
    s = s.replace(anchor, patch + anchor, 1)
    open(p, 'w').write(s)
    print('local_storage.js: preinstall loader added')
else:
    print('local_storage.js: already patched')
PY

# --- 2. code.js: run the preinstall before the provider/storage pipeline ---
python3 - <<'PY'
p = 'scripts/code.js'
s = open(p).read()
if 'SCRIVAR-REBRAND' not in s:
    anchor = "\t\tawait AI.loadInternalProviders();"
    if anchor not in s:
        raise SystemExit('ERROR: code.js anchor (await AI.loadInternalProviders();) not found')
    patch = ("\t\t/* SCRIVAR-REBRAND (P3): seed first-run provider/model config from ./preinstall.json */\n"
             "\t\tawait AI.Storage.preinstall();\n")
    s = s.replace(anchor, patch + anchor, 1)
    open(p, 'w').write(s)
    print('code.js: preinstall call added')
else:
    print('code.js: already patched')
PY

# --- 3. preinstall.json (plugin root, fetched relative to index.html) ------
# Localhost only — the launcher's private AI proxy. No Scrivar API URLs,
# no keys. capabilities 1 == AI.CapabilitiesUI.Chat; endpoints [1] ==
# AI.Endpoints.Types.v1.Chat_Completions.
cat > preinstall.json <<'JSON'
{
	"providers": {
		"Scrivar AI": {
			"name": "Scrivar AI",
			"url": "http://127.0.0.1:41317/v1",
			"key": "",
			"models": [
				{
					"id": "scrivar-ai",
					"name": "Scrivar AI",
					"object": "model",
					"endpoints": [1],
					"options": {}
				}
			]
		}
	},
	"models": [
		{
			"id": "scrivar-ai",
			"name": "Scrivar AI",
			"provider": "Scrivar AI",
			"capabilities": 1
		}
	],
	"actions": {
		"Chat": { "model": "scrivar-ai" },
		"Summarization": { "model": "scrivar-ai" },
		"Translation": { "model": "scrivar-ai" },
		"TextAnalyze": { "model": "scrivar-ai" }
	}
}
JSON

python3 -c "import json; json.load(open('preinstall.json')); print('preinstall.json: valid JSON')"
echo "patch-ai-plugin done."
