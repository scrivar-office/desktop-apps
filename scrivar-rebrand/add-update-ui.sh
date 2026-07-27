#!/bin/bash
# Scrivar Office rebrand — surface updates in the start page (v1.0.8).
#
# Before this, updates were invisible and unconfigurable: the launcher checked
# once per launch, downloaded silently and installed on exit. The user could not
# see their version, learn an update existed, trigger one, or turn it off.
#
# This adds two things to the loginpage:
#   1. A rail FOOTER under Settings — version line, a status chip, and a thin
#      progress bar while downloading.
#   2. Two SETTINGS rows — an "Automatic updates" toggle and a "Check for
#      updates" button.
#
# AGPL note: the fork carries NO update logic — no feed URL, no version
# comparison, no download or install code. It polls the resident launcher's
# loopback API (127.0.0.1:41317, origin-gated, the same server the AI plugin
# already reads) and renders whatever it reports; buttons POST intent back.
# Every decision stays in the private launcher, exactly like add-cloud-ai.sh
# and add-support.sh.
#
# The launcher owns the restart too: "Restart to update" POSTs /update/restart,
# and the LAUNCHER asks this app to quit via an Apple Event (so unsaved
# documents prompt normally and the user can cancel). The fork never quits
# itself and never kills anything.
#
# Run order: independent of the other loginpage sweeps (all idempotent). Rebuild
# the loginpage (grunt in common/loginpage/build) after — NO C++ rebuild needed.
set -euo pipefail
cd "$(dirname "$0")/../common/loginpage"

# --- 1. panels.js: rail footer + polling ------------------------------------
python3 - <<'PY'
p = 'src/panels.js'
s = open(p).read()
if 'SCRIVAR-REBRAND: update footer' in s:
    print('panels.js: already patched')
else:
    # (a) footer markup — last item in the rail column, after the hidden About.
    anchor = (
        "                    <span class=\"text\" l10n>${utils.Lang.actAbout}</span>\n"
        "                  </a>\n"
        "              </li>\n"
    )
    if anchor not in s:
        raise SystemExit('ERROR: panels.js About <li> anchor not found')
    # Inline styles: the rail is our navy gradient in every theme, so
    # white-alpha text is readable without depending on the LESS build.
    footer = (
        "              <!-- SCRIVAR-REBRAND: update footer (status from the launcher's loopback API) -->\n"
        "              <li class=\"menu-item\" id=\"scrivar-update-foot\" style=\"display:none;margin-top:auto;padding:10px 12px 4px;cursor:pointer;\">\n"
        "                <div id=\"scrivar-update-version\" style=\"font-size:11px;color:rgba(255,255,255,.55);line-height:1.5;\"></div>\n"
        "                <div id=\"scrivar-update-chip\" style=\"display:none;margin-top:5px;font-size:11px;font-weight:600;padding:3px 9px;border-radius:999px;background:rgba(255,255,255,.16);color:#fff;\"></div>\n"
        "                <div id=\"scrivar-update-bar\" style=\"display:none;margin-top:6px;height:3px;border-radius:2px;background:rgba(255,255,255,.18);overflow:hidden;\">\n"
        "                  <div id=\"scrivar-update-bar-fill\" style=\"height:100%;width:0%;background:#fff;transition:width .25s ease;\"></div>\n"
        "                </div>\n"
        "              </li>\n"
    )
    s = s.replace(anchor, anchor + footer, 1)

    # (b) poller + click handling. Appended inside the same $(document).ready
    #     block, right after the rail's click registration.
    click_anchor = "    $('.tool-menu').on('click', '> .menu-item > a', onActionClick);\n"
    if click_anchor not in s:
        raise SystemExit('ERROR: panels.js tool-menu click-registration anchor not found')
    logic = r"""
    /* SCRIVAR-REBRAND: update footer — render the launcher's update state.
       The fork holds no update logic: it GETs status from the resident
       launcher over loopback and POSTs the user's intent back. If the launcher
       is not up (or this is not a Scrivar build) every call fails and the whole
       footer stays hidden, so nothing here can break the start page. */
    (function scrivarUpdateFooter() {
        var API = 'http://127.0.0.1:41317';
        var el = {
            root: document.getElementById('scrivar-update-foot'),
            version: document.getElementById('scrivar-update-version'),
            chip: document.getElementById('scrivar-update-chip'),
            bar: document.getElementById('scrivar-update-bar'),
            fill: document.getElementById('scrivar-update-bar-fill')
        };
        if (!el.root) return;
        var last = null;
        var busy = false;

        function post(path, body) {
            return fetch(API + path, {
                method: 'POST',
                headers: {'Content-Type': 'application/json'},
                body: JSON.stringify(body || {})
            }).catch(function(){ return null; });
        }

        function render(s) {
            last = s;
            el.root.style.display = 'block';
            el.version.textContent = 'Version ' + (s.currentVersion || '');
            var chip = '', bar = false, pct = 0;
            if (s.state === 'checking')          { chip = 'Checking…'; }
            else if (s.state === 'downloading')  { chip = 'Downloading ' + (s.percent||0) + '%'; bar = true; pct = s.percent||0; }
            else if (s.canInstall)               { chip = 'Restart to update'; }
            else if (s.state === 'available')    { chip = 'Update to ' + (s.targetVersion||'') ; }
            else if (s.state === 'error')        { chip = 'Update failed — retry'; }
            el.chip.textContent = chip;
            el.chip.style.display = chip ? 'inline-block' : 'none';
            el.bar.style.display = bar ? 'block' : 'none';
            el.fill.style.width = pct + '%';
            el.root.title = chip || 'Click to check for updates';
        }

        function poll() {
            fetch(API + '/update/status', {cache: 'no-store'})
                .then(function(r){ return r.ok ? r.json() : null; })
                .then(function(s){ if (s && s.ok) render(s); else el.root.style.display = 'none'; })
                .catch(function(){ el.root.style.display = 'none'; });
        }

        el.root.addEventListener('click', function() {
            if (busy || !last) return;
            busy = true;
            setTimeout(function(){ busy = false; }, 800);
            if (last.canInstall) {
                /* The LAUNCHER asks this app to quit (Apple Event → save
                   prompts). We only signal intent; if the user cancels a save
                   prompt nothing installs and the footer stays as it was. */
                post('/update/restart');
            } else if (last.state === 'available') {
                post('/update/download');
            } else if (last.state !== 'downloading' && last.state !== 'checking') {
                post('/update/check');
            }
            setTimeout(poll, 300);
        });

        poll();
        setInterval(poll, 1500);
    })();
"""
    s = s.replace(click_anchor, click_anchor + logic, 1)
    open(p, 'w').write(s)
    print('panels.js: update footer + poller added')
PY
grep -q 'SCRIVAR-REBRAND: update footer' src/panels.js || { echo "ERROR: panels.js patch failed"; exit 1; }

# --- 2. panelsettings.js: auto-update toggle + check button -----------------
python3 - <<'PY'
p = 'src/panelsettings.js'
s = open(p).read()
if 'SCRIVAR-REBRAND: automatic updates' in s:
    print('panelsettings.js: already patched')
else:
    # Place directly above the Apply button block so it reads as a settings row.
    anchor = "                                        <!-- temporary elements section -->\n"
    if anchor not in s:
        raise SystemExit('ERROR: panelsettings.js temporary-section anchor not found')
    row = (
        "                                        <!-- SCRIVAR-REBRAND: automatic updates (state lives in the launcher) -->\n"
        "                                        <div class='settings-field'>\n"
        "                                            <section class='switch-labeled hbox' id='scrivar-box-autoupdate'>\n"
        "                                                <input type=\"checkbox\" class=\"checkbox\" id=\"scrivar-autoupdate\">\n"
        "                                                <label for=\"scrivar-autoupdate\" class='sett__caption'>${_lang.settScrivarAutoUpdate}</label>\n"
        "                                            </section>\n"
        "                                            <div class='sett--label-lift-top hbox' style='margin-top:6px;'>\n"
        "                                                <a class='link link--sizem link--gray' draggable='false' href='#' id='scrivar-check-updates'>${_lang.settScrivarCheckUpdates}</a>\n"
        "                                                <span id='scrivar-update-settings-status' style='margin-left:10px;font-size:12px;opacity:.7;'></span>\n"
        "                                            </div>\n"
        "                                        </div>\n"
    )
    s = s.replace(anchor, row + anchor, 1)

    # Wire it up on panel render. Appended at the end of the file so it runs
    # after the panel exists; guarded so it binds only once.
    s += r"""

/* SCRIVAR-REBRAND: automatic-updates row. The preference and every version
   decision live in the launcher; this only reflects and posts. Polls slowly so
   the label tracks a download started elsewhere (e.g. the rail footer). */
(function scrivarUpdateSettings() {
    var API = 'http://127.0.0.1:41317';
    var bound = false;

    function label(s) {
        if (!s) return '';
        if (s.state === 'checking') return 'Checking…';
        if (s.state === 'downloading') return 'Downloading ' + (s.percent || 0) + '%';
        if (s.canInstall) return 'Ready — restart to update';
        if (s.state === 'available') return 'Update ' + (s.targetVersion || '') + ' available';
        if (s.state === 'error') return 'Last check failed';
        if (s.state === 'none') return 'Up to date';
        return '';
    }

    function sync() {
        var box = document.getElementById('scrivar-autoupdate');
        var status = document.getElementById('scrivar-update-settings-status');
        var link = document.getElementById('scrivar-check-updates');
        if (!box) return;
        fetch(API + '/update/status', {cache: 'no-store'})
            .then(function(r){ return r.ok ? r.json() : null; })
            .then(function(s){
                if (!s || !s.ok) return;
                if (document.activeElement !== box) box.checked = !!s.autoUpdate;
                if (status) status.textContent = label(s);
                if (!bound) {
                    bound = true;
                    box.addEventListener('change', function() {
                        fetch(API + '/update/settings', {
                            method: 'POST',
                            headers: {'Content-Type': 'application/json'},
                            body: JSON.stringify({autoUpdate: !!box.checked})
                        }).catch(function(){});
                    });
                    link && link.addEventListener('click', function(e) {
                        e.preventDefault();
                        if (status) status.textContent = 'Checking…';
                        fetch(API + '/update/check', {method: 'POST'}).catch(function(){});
                        setTimeout(sync, 600);
                    });
                }
            })
            .catch(function(){});
    }

    setInterval(sync, 2000);
    sync();
})();
"""
    open(p, 'w').write(s)
    print('panelsettings.js: automatic-updates row added')
PY
grep -q 'SCRIVAR-REBRAND: automatic updates' src/panelsettings.js || { echo "ERROR: panelsettings.js patch failed"; exit 1; }

# --- 3. locale.js: labels ---------------------------------------------------
python3 - <<'PY'
p = 'src/locale.js'
s = open(p).read()
if 'settScrivarAutoUpdate' in s:
    print('locale.js: already has the update labels')
else:
    anchor = "    actSettings: 'Settings',\n"
    if anchor not in s:
        raise SystemExit('ERROR: locale.js actSettings anchor not found')
    s = s.replace(anchor, anchor
        + "    settScrivarAutoUpdate: 'Install updates automatically', /* SCRIVAR-REBRAND */\n"
        + "    settScrivarCheckUpdates: 'Check for updates', /* SCRIVAR-REBRAND */\n", 1)
    open(p, 'w').write(s)
    print('locale.js: update labels added')
PY
grep -q 'settScrivarAutoUpdate' src/locale.js || { echo "ERROR: locale.js patch failed"; exit 1; }

echo "add-update-ui done:"
echo "  panels.js footer:        $(grep -c 'scrivar-update-foot' src/panels.js) reference(s)"
echo "  panelsettings.js row:    $(grep -c 'scrivar-autoupdate' src/panelsettings.js) reference(s)"
echo "  locale.js labels:        $(grep -c 'settScrivar' src/locale.js)"
