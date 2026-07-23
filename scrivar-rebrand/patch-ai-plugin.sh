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

# --- 4. settings.js: LOCK provider management -------------------------------
# Scrivar Cloud & AI is the ONLY provider. Remove the two UI entry points that
# let a user add/edit/delete providers or models from the "AI configuration"
# dialog: (a) the "Add AI Model" pseudo-entry appended to every per-task
# dropdown, and (b) the "Edit AI models" link (which opens the models-list /
# add-edit / custom-providers windows). After seeding, only the "Scrivar AI"
# model exists, so each per-task dropdown becomes a single fixed choice.
python3 - <<'PY'
p = 'scripts/settings.js'
s = open(p).read()
if 'SCRIVAR-LOCK' in s:
    print('settings.js: already locked')
else:
    changed = False

    # (a) Drop the separator + "Add AI Model" entry from the dropdown options.
    add_block = """		options.push(
			{
				text: '-',
				children: []
			},
			{
				id: 'add',
				text: window.Asc.plugin.tr("Add AI Model"),
				handler: function() {
					window.Asc.plugin.sendToPlugin("onOpenAddModal");
				}
			}
		);
"""
    if add_block not in s:
        raise SystemExit('ERROR: settings.js anchor (Add AI Model options.push block) not found')
    s = s.replace(add_block,
        "		/* SCRIVAR-LOCK: Scrivar AI is the only provider — no \"Add AI Model\" entry. */\n",
        1)
    changed = True

    # (b) Neutralise the "Edit AI models" link: never wire the click, and hide it.
    edit_anchor = """	$('#edit-ai-models label').click(function(e) {
		window.Asc.plugin.sendToPlugin("onOpenAiModelsModal");
	});
"""
    if edit_anchor not in s:
        raise SystemExit('ERROR: settings.js anchor (#edit-ai-models click) not found')
    s = s.replace(edit_anchor,
        "	/* SCRIVAR-LOCK: hide the \"Edit AI models\" link — provider/model set is fixed. */\n"
        "	$('#edit-ai-models').hide();\n",
        1)
    changed = True

    if changed:
        open(p, 'w').write(s)
        print('settings.js: provider-management UI removed (Add AI Model + Edit AI models)')
PY
grep -q 'SCRIVAR-LOCK' scripts/settings.js || { echo "ERROR: settings.js lock failed"; exit 1; }

# --- 5. code.js: hard backstop for the mutation windows --------------------
# Defence in depth: even if a crafted sendToPlugin reached them, the windows
# that add/edit/delete providers or models must never open.
python3 - <<'PY'
p = 'scripts/code.js'
s = open(p).read()
if 'SCRIVAR-LOCK' in s:
    print('code.js: already locked')
else:
    guards = [
        ('function onOpenAiModelsModal() {\n',
         'function onOpenAiModelsModal() {\n\treturn; /* SCRIVAR-LOCK: AI models list (add/edit/delete) disabled */\n'),
        ('function onOpenEditModal(data) {\n',
         'function onOpenEditModal(data) {\n\treturn; /* SCRIVAR-LOCK: add/edit model window disabled */\n'),
        ('function onOpenCustomProvidersModal() {\n',
         'function onOpenCustomProvidersModal() {\n\treturn; /* SCRIVAR-LOCK: custom-providers window disabled */\n'),
    ]
    for anchor, repl in guards:
        if anchor not in s:
            raise SystemExit('ERROR: code.js anchor not found: ' + anchor.strip())
        s = s.replace(anchor, repl, 1)
    open(p, 'w').write(s)
    print('code.js: mutation-window openers guarded (models list / add-edit / custom providers)')
PY
grep -q 'SCRIVAR-LOCK' scripts/code.js || { echo "ERROR: code.js lock failed"; exit 1; }

# --- 6. local_storage.js: no-op the model mutators -------------------------
# Final backstop at the storage layer so nothing (UI or engine) can grow the
# provider/model set. The preinstall seeder writes localStorage directly (not
# via addModel), so it is unaffected.
python3 - <<'PY'
p = 'scripts/engine/local_storage.js'
s = open(p).read()
if 'SCRIVAR-LOCK' in s:
    print('local_storage.js: already locked')
else:
    changed = False
    for name, anchor in [
        ('addModel',    '\tAI.Storage.addModel = function(model) {\n'),
        ('removeModel',  '\tAI.Storage.removeModel = function(modelId) {\n'),
    ]:
        if anchor in s:
            s = s.replace(anchor,
                anchor + '\t\treturn; /* SCRIVAR-LOCK: provider/model set is fixed to Scrivar AI */\n',
                1)
            changed = True
        else:
            print('local_storage.js: NOTE anchor for %s not found (skipped)' % name)
    if changed:
        open(p, 'w').write(s)
        print('local_storage.js: model mutators no-oped')
PY

# --- 7. chat.js: Subscribe-to-Cloud-&-AI CTA in the empty-state -------------
# A non-subscriber sees an intuitive "Subscribe" card BEFORE sending anything.
# Subscription state comes from the resident launcher's localhost /status (no
# Scrivar API/token in the fork — the plugin already talks to 127.0.0.1:41317
# for chat); the CTA opens the launcher manage window via the custom scheme.
python3 - <<'PY'
p = 'scripts/chat.js'
s = open(p).read()
if 'SCRIVAR-SUBSCRIBE' in s:
    print('chat.js: already has subscribe CTA')
else:
    anchor = '\t\tdocument.getElementById("chat_wrapper").addEventListener("click", function(e) {\n'
    if anchor not in s:
        raise SystemExit('ERROR: chat.js chat_wrapper click anchor not found')
    inject = (
        "\t\t// SCRIVAR-SUBSCRIBE: when Cloud & AI is not active, show a Subscribe\n"
        "\t\t// card in the empty-state. State from the resident launcher /status;\n"
        "\t\t// the button opens the launcher manage window (AGPL: fork holds only\n"
        "\t\t// the localhost URL + the custom scheme, no account/token logic).\n"
        "\t\ttry {\n"
        "\t\t\tfetch('http://127.0.0.1:41317/status').then(function(r){ return r.json(); }).then(function(st){\n"
        "\t\t\t\tif (st && st.subscribed) return;\n"
        "\t\t\t\tif (document.getElementById('scrivar-subscribe-cta')) return;\n"
        "\t\t\t\tvar host = document.getElementById('start_panel') || document.getElementById('chat');\n"
        "\t\t\t\tif (!host) return;\n"
        "\t\t\t\tvar cta = document.createElement('div');\n"
        "\t\t\t\tcta.id = 'scrivar-subscribe-cta';\n"
        "\t\t\t\tcta.style.cssText = 'margin:10px 12px;padding:12px;border:1px solid var(--border-Regular,#e0e0e0);border-radius:8px;text-align:center;';\n"
        "\t\t\t\tvar msg = document.createElement('div');\n"
        "\t\t\t\tmsg.className = 'i18n';\n"
        "\t\t\t\tmsg.style.cssText = 'font-size:13px;margin-bottom:8px;';\n"
        "\t\t\t\tmsg.textContent = 'Cloud & AI is not active. Subscribe to use AI features.';\n"
        "\t\t\t\tvar btn = document.createElement('button');\n"
        "\t\t\t\tbtn.className = 'form-control btn-text-default i18n';\n"
        "\t\t\t\tbtn.textContent = 'Subscribe to Cloud & AI';\n"
        "\t\t\t\tbtn.addEventListener('click', function(){ window.open('scrivar-office://manage'); });\n"
        "\t\t\t\tcta.appendChild(msg); cta.appendChild(btn);\n"
        "\t\t\t\thost.insertBefore(cta, host.firstChild);\n"
        "\t\t\t}).catch(function(){});\n"
        "\t\t} catch (e) {}\n\n"
    )
    s = s.replace(anchor, inject + anchor, 1)
    open(p, 'w').write(s)
    print('chat.js: subscribe CTA added')
PY
grep -q 'SCRIVAR-SUBSCRIBE' scripts/chat.js || { echo "ERROR: chat.js subscribe CTA failed"; exit 1; }

# --- 8. settings.js: Cloud & AI status row atop the AI configuration dialog -
python3 - <<'PY'
p = 'scripts/settings.js'
s = open(p).read()
if 'SCRIVAR-SUBSCRIBE' in s:
    print('settings.js: already has status row')
else:
    anchor = "\t$('#edit-ai-models').hide();\n"
    if anchor not in s:
        raise SystemExit('ERROR: settings.js SCRIVAR-LOCK edit-ai-models anchor not found')
    inject = (
        "\n\t// SCRIVAR-SUBSCRIBE: Cloud & AI status row atop the dialog. State from\n"
        "\t// the resident launcher /status; Subscribe opens the manage window.\n"
        "\ttry {\n"
        "\t\tfetch('http://127.0.0.1:41317/status').then(function(r){ return r.json(); }).then(function(st){\n"
        "\t\t\tif (document.getElementById('scrivar-cloudai-row')) return;\n"
        "\t\t\tvar row = document.createElement('div');\n"
        "\t\t\trow.id = 'scrivar-cloudai-row';\n"
        "\t\t\trow.style.cssText = 'margin-bottom:10px;font-size:13px;';\n"
        "\t\t\tif (st && st.subscribed) {\n"
        "\t\t\t\tvar b = document.createElement('b'); b.textContent = 'Cloud & AI';\n"
        "\t\t\t\tvar a = document.createElement('span'); a.className = 'i18n'; a.textContent = ': Active';\n"
        "\t\t\t\trow.appendChild(b); row.appendChild(a);\n"
        "\t\t\t} else {\n"
        "\t\t\t\tvar lbl = document.createElement('span'); lbl.className = 'i18n'; lbl.textContent = 'Cloud & AI is not active.';\n"
        "\t\t\t\tvar btn = document.createElement('button'); btn.className = 'form-control btn-text-default i18n';\n"
        "\t\t\t\tbtn.style.cssText = 'display:block;margin-top:6px;'; btn.textContent = 'Subscribe to Cloud & AI';\n"
        "\t\t\t\tbtn.addEventListener('click', function(){ window.open('scrivar-office://manage'); });\n"
        "\t\t\t\trow.appendChild(lbl); row.appendChild(btn);\n"
        "\t\t\t}\n"
        "\t\t\tvar desc = document.getElementById('description');\n"
        "\t\t\tif (desc && desc.parentNode) desc.parentNode.insertBefore(row, desc);\n"
        "\t\t}).catch(function(){});\n"
        "\t} catch (e) {}\n"
    )
    s = s.replace(anchor, anchor + inject, 1)
    open(p, 'w').write(s)
    print('settings.js: Cloud & AI status row added')
PY
grep -q 'SCRIVAR-SUBSCRIBE' scripts/settings.js || { echo "ERROR: settings.js status row failed"; exit 1; }

echo "patch-ai-plugin done."
