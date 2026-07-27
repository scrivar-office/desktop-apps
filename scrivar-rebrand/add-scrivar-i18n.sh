#!/bin/bash
# Scrivar Office rebrand — localize the Scrivar-added start-page strings.
#
# Every Scrivar addition to the loginpage shipped English-only, including the
# v1.0.4 "Cloud & AI" rail entry — so a French or Japanese user saw one English
# label sitting among 46 translated ones. This sweep fixes all of them at once:
#
#   1. Adds locale KEYS for the update footer's chips (previously hardcoded
#      English inside panels.js / panelsettings.js).
#   2. Rewrites those hardcoded strings to read from utils.Lang / _lang.
#   3. Adds translations to the languages Scrivar supports as a product
#      (fr, es, de, it, ja, zh-CN, zh-TW).
#
# The other ~40 locales keep the English text automatically: locale.js does
# `utils.Lang = Object.assign({}, l10n.en)` and then overlays the chosen
# language, so a missing key falls back to English rather than rendering blank.
# That is the same behaviour upstream relies on for its own partial locales.
#
# RUN ORDER: after add-cloud-ai.sh, add-support.sh and add-update-ui.sh — it
# rewrites strings those sweeps insert. Idempotent like the others.
set -euo pipefail
cd "$(dirname "$0")/../common/loginpage"

# --- 1. English base keys for the update footer -----------------------------
python3 - <<'PY'
p = 'src/locale.js'
s = open(p).read()
if 'updRestart' in s:
    print('locale.js: already has the update strings')
else:
    anchor = "    settScrivarAutoUpdate:"
    if anchor not in s:
        raise SystemExit('ERROR: locale.js — run add-update-ui.sh first')
    keys = (
        "    updVersion: 'Version', /* SCRIVAR-REBRAND */\n"
        "    updChecking: 'Checking…', /* SCRIVAR-REBRAND */\n"
        "    updUpdateTo: 'Update to', /* SCRIVAR-REBRAND */\n"
        "    updDownloading: 'Downloading', /* SCRIVAR-REBRAND */\n"
        "    updRestart: 'Restart to update', /* SCRIVAR-REBRAND */\n"
        "    updFailed: 'Update failed — retry', /* SCRIVAR-REBRAND */\n"
        "    updUpToDate: 'Up to date', /* SCRIVAR-REBRAND */\n"
    )
    s = s.replace(anchor, keys + anchor, 1)
    open(p, 'w').write(s)
    print('locale.js: update strings added')
PY

# --- 2. panels.js — chips read from Lang ------------------------------------
python3 - <<'PY'
p = 'src/panels.js'
s = open(p).read()
if "utils.Lang.updRestart" in s:
    print('panels.js: already localized')
else:
    subs = [
        ("chip = 'Checking…';", "chip = utils.Lang.updChecking;"),
        ("chip = 'Downloading ' + (s.percent||0) + '%';",
         "chip = utils.Lang.updDownloading + ' ' + (s.percent||0) + '%';"),
        ("chip = 'Restart to update';", "chip = utils.Lang.updRestart;"),
        ("chip = 'Update to ' + (s.targetVersion||'') ;",
         "chip = utils.Lang.updUpdateTo + ' ' + (s.targetVersion||'');"),
        ("chip = 'Update failed — retry';", "chip = utils.Lang.updFailed;"),
        ("el.version.textContent = 'Version ' + (s.currentVersion || '');",
         "el.version.textContent = utils.Lang.updVersion + ' ' + (s.currentVersion || '');"),
        ("el.root.title = chip || 'Click to check for updates';",
         "el.root.title = chip || utils.Lang.settScrivarCheckUpdates;"),
    ]
    missing = [a for a, _ in subs if a not in s]
    if missing:
        raise SystemExit('ERROR: panels.js — expected strings not found: %r' % missing[:2])
    for a, b in subs:
        s = s.replace(a, b, 1)
    open(p, 'w').write(s)
    print('panels.js: chips localized')
PY

# --- 3. panelsettings.js — status label reads from Lang ---------------------
python3 - <<'PY'
p = 'src/panelsettings.js'
s = open(p).read()
if 'utils.Lang.updRestart' in s or "_l.updRestart" in s:
    print('panelsettings.js: already localized')
else:
    subs = [
        ("if (s.state === 'checking') return 'Checking…';",
         "if (s.state === 'checking') return utils.Lang.updChecking;"),
        ("if (s.state === 'downloading') return 'Downloading ' + (s.percent || 0) + '%';",
         "if (s.state === 'downloading') return utils.Lang.updDownloading + ' ' + (s.percent || 0) + '%';"),
        ("if (s.canInstall) return 'Ready — restart to update';",
         "if (s.canInstall) return utils.Lang.updRestart;"),
        ("if (s.state === 'available') return 'Update ' + (s.targetVersion || '') + ' available';",
         "if (s.state === 'available') return utils.Lang.updUpdateTo + ' ' + (s.targetVersion || '');"),
        ("if (s.state === 'error') return 'Last check failed';",
         "if (s.state === 'error') return utils.Lang.updFailed;"),
        ("if (s.state === 'none') return 'Up to date';",
         "if (s.state === 'none') return utils.Lang.updUpToDate;"),
        ("if (status) status.textContent = 'Checking…';",
         "if (status) status.textContent = utils.Lang.updChecking;"),
    ]
    missing = [a for a, _ in subs if a not in s]
    if missing:
        raise SystemExit('ERROR: panelsettings.js — expected strings not found: %r' % missing[:2])
    for a, b in subs:
        s = s.replace(a, b, 1)
    open(p, 'w').write(s)
    print('panelsettings.js: status labels localized')
PY

# --- 4. Translations for the languages Scrivar supports ---------------------
python3 - <<'PY'
import re

T = {
 'fr': {
  'actCloudAI': "Cloud et IA", 'actHelpContact': "Aide et contact",
  'settScrivarAutoUpdate': "Installer les mises à jour automatiquement",
  'settScrivarCheckUpdates': "Rechercher des mises à jour",
  'updVersion': "Version", 'updChecking': "Vérification…", 'updUpdateTo': "Mettre à jour vers",
  'updDownloading': "Téléchargement", 'updRestart': "Redémarrer pour mettre à jour",
  'updFailed': "Échec de la mise à jour — réessayer", 'updUpToDate': "À jour",
 },
 'es': {
  'actCloudAI': "Nube e IA", 'actHelpContact': "Ayuda y contacto",
  'settScrivarAutoUpdate': "Instalar actualizaciones automáticamente",
  'settScrivarCheckUpdates': "Buscar actualizaciones",
  'updVersion': "Versión", 'updChecking': "Comprobando…", 'updUpdateTo': "Actualizar a",
  'updDownloading': "Descargando", 'updRestart': "Reiniciar para actualizar",
  'updFailed': "Error al actualizar — reintentar", 'updUpToDate': "Actualizado",
 },
 'de': {
  'actCloudAI': "Cloud & KI", 'actHelpContact': "Hilfe & Kontakt",
  'settScrivarAutoUpdate': "Updates automatisch installieren",
  'settScrivarCheckUpdates': "Nach Updates suchen",
  'updVersion': "Version", 'updChecking': "Wird geprüft…", 'updUpdateTo': "Update auf",
  'updDownloading': "Wird geladen", 'updRestart': "Zum Aktualisieren neu starten",
  'updFailed': "Update fehlgeschlagen — erneut versuchen", 'updUpToDate': "Aktuell",
 },
 'it': {
  'actCloudAI': "Cloud e IA", 'actHelpContact': "Aiuto e contatti",
  'settScrivarAutoUpdate': "Installa gli aggiornamenti automaticamente",
  'settScrivarCheckUpdates': "Verifica aggiornamenti",
  'updVersion': "Versione", 'updChecking': "Controllo…", 'updUpdateTo': "Aggiorna a",
  'updDownloading': "Download", 'updRestart': "Riavvia per aggiornare",
  'updFailed': "Aggiornamento non riuscito — riprova", 'updUpToDate': "Aggiornato",
 },
 'ja': {
  'actCloudAI': "クラウドとAI", 'actHelpContact': "ヘルプとお問い合わせ",
  'settScrivarAutoUpdate': "アップデートを自動的にインストール",
  'settScrivarCheckUpdates': "アップデートを確認",
  'updVersion': "バージョン", 'updChecking': "確認中…", 'updUpdateTo': "更新",
  'updDownloading': "ダウンロード中", 'updRestart': "再起動して更新",
  'updFailed': "更新に失敗しました — 再試行", 'updUpToDate': "最新です",
 },
 'zh-CN': {
  'actCloudAI': "云与 AI", 'actHelpContact': "帮助与联系",
  'settScrivarAutoUpdate': "自动安装更新",
  'settScrivarCheckUpdates': "检查更新",
  'updVersion': "版本", 'updChecking': "正在检查…", 'updUpdateTo': "更新到",
  'updDownloading': "正在下载", 'updRestart': "重启以更新",
  'updFailed': "更新失败 — 重试", 'updUpToDate': "已是最新",
 },
 'zh-TW': {
  'actCloudAI': "雲端與 AI", 'actHelpContact': "說明與聯絡",
  'settScrivarAutoUpdate': "自動安裝更新",
  'settScrivarCheckUpdates': "檢查更新",
  'updVersion': "版本", 'updChecking': "正在檢查…", 'updUpdateTo': "更新到",
  'updDownloading': "正在下載", 'updRestart': "重新啟動以更新",
  'updFailed': "更新失敗 — 重試", 'updUpToDate': "已是最新",
 },
}

for lang, pairs in T.items():
    p = 'locale/%s.js' % lang
    try:
        s = open(p, encoding='utf-8').read()
    except FileNotFoundError:
        print('  %-6s SKIP (no locale file)' % lang); continue
    if 'updRestart' in s:
        print('  %-6s already translated' % lang); continue
    # Insert before the final closing brace of the exported object.
    idx = s.rstrip().rfind('}')
    if idx == -1:
        print('  %-6s SKIP (unrecognised shape)' % lang); continue
    block = '\n' + ''.join(
        "    %s: %s,\n" % (k, ("'" + v.replace("'", "\\'") + "'"))
        for k, v in pairs.items()
    )
    # Make sure the preceding entry ends with a comma.
    head = s[:idx].rstrip()
    if not head.endswith(',') and not head.endswith('{'):
        head += ','
    s = head + block + s[idx:]
    open(p, 'w', encoding='utf-8').write(s)
    print('  %-6s +%d strings' % (lang, len(pairs)))
PY

echo "add-scrivar-i18n done:"
echo "  english keys:   $(grep -c 'SCRIVAR-REBRAND' src/locale.js)"
echo "  panels.js Lang: $(grep -c 'utils.Lang.upd' src/panels.js)"
echo "  settings Lang:  $(grep -c 'utils.Lang.upd' src/panelsettings.js)"
