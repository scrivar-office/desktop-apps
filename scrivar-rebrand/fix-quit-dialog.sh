#!/bin/bash
# Scrivar Office rebrand — honest "quit with unsaved documents" dialog (v1.0.14).
#
# Upstream's Cocoa alert (3 call sites: AppDelegate applicationShouldTerminate
# + two quit paths in ASCCommonViewController) read:
#   "You have 1 Scrivar Office documents with unconfirmed changes. Do you want
#    to review these changes before quitting?"   [Review Changes...] [Cancel]
#   [Delete and Quit]
# "Delete and Quit" sounds like it deletes the FILES; it actually discards the
# unsaved edits and quits. "unconfirmed" is not a word users know, and "1 …
# documents" is broken grammar. New copy (singular/plural, macOS-style):
#   "You have a document with unsaved changes. Do you want to review it before
#    quitting?" / "You have N documents with unsaved changes. Do you want to
#    review them before quitting?"
#   info: "If you don't review your changes, they will be lost."
#   buttons: [Review Changes…] [Cancel] [Quit Without Saving]
# Behaviour is unchanged — only strings. New keys are translated for the
# languages Scrivar supports (fr/es/de/it/ja/zh-Hans/zh-Hant); other locales
# fall back to English, as with every Scrivar-added string.
#
# Native shell change: needs a Stage 2 (xcodebuild) rebuild, not Stage 1.
# Idempotent (marker SCRIVAR-QUIT).
set -euo pipefail
cd "$(dirname "$0")/../macos/ONLYOFFICE"

python3 - <<'PY'
import re
files = ['AppDelegate.mm', 'Code/Controllers/Common/ASCCommonViewController.mm']
OLD_BTN = 'NSLocalizedString(@"Delete and Quit", nil)'
NEW_BTN = 'NSLocalizedString(@"Quit Without Saving", nil) /* SCRIVAR-QUIT */'
OLD_MSG = ('[alert setMessageText:[NSString stringWithFormat:NSLocalizedString(@"You have %ld %@ documents with '
           'unconfirmed changes. Do you want to review these changes before quitting?", nil), (long)unsaved, productName]];')
NEW_MSG = ('(void)productName; /* SCRIVAR-QUIT */\n'
           '{INDENT}[alert setMessageText:(unsaved == 1\n'
           '{INDENT}    ? NSLocalizedString(@"You have a document with unsaved changes. Do you want to review it before quitting?", nil)\n'
           '{INDENT}    : [NSString stringWithFormat:NSLocalizedString(@"You have %ld documents with unsaved changes. Do you want to review them before quitting?", nil), (long)unsaved])];')
OLD_INFO = 'NSLocalizedString(@"If you don\'t review your documents, all your changeses will be lost.", nil)'
NEW_INFO = 'NSLocalizedString(@"If you don\'t review your changes, they will be lost.", nil)'
OLD_REVIEW = 'NSLocalizedString(@"Review Changes...", nil)'
NEW_REVIEW = 'NSLocalizedString(@"Review Changes…", nil)'
total = 0
for f in files:
    s = open(f, encoding='utf-8').read()
    if 'SCRIVAR-QUIT' in s:
        print(f + ': already patched'); continue
    n = s.count(OLD_BTN)
    if n == 0 or s.count(OLD_MSG) != n or s.count(OLD_INFO) != n:
        raise SystemExit('ERROR: %s: quit-dialog anchors not found consistently' % f)
    def msg_repl(m):
        indent = m.group(1)
        return indent + NEW_MSG.replace('{INDENT}', indent)
    s = re.sub(r'([ \t]*)' + re.escape(OLD_MSG), msg_repl, s)
    s = s.replace(OLD_BTN, NEW_BTN).replace(OLD_INFO, NEW_INFO)
    # "Review Changes..." only inside these alerts (same count as the button)
    s = s.replace(OLD_REVIEW, NEW_REVIEW, n)
    open(f, 'w', encoding='utf-8').write(s)
    total += n
    print('%s: %d quit dialog(s) reworded' % (f, n))

T = {
  'fr.lproj':        ('Quitter sans enregistrer', 'Vous avez un document avec des modifications non enregistrées. Voulez-vous le vérifier avant de quitter ?', 'Vous avez %ld documents avec des modifications non enregistrées. Voulez-vous les vérifier avant de quitter ?', 'Si vous ne vérifiez pas vos modifications, elles seront perdues.', 'Vérifier les modifications…'),
  'es.lproj':        ('Salir sin guardar', 'Tiene un documento con cambios sin guardar. ¿Desea revisarlo antes de salir?', 'Tiene %ld documentos con cambios sin guardar. ¿Desea revisarlos antes de salir?', 'Si no revisa sus cambios, se perderán.', 'Revisar cambios…'),
  'de.lproj':        ('Ohne Sichern beenden', 'Sie haben ein Dokument mit ungesicherten Änderungen. Möchten Sie es vor dem Beenden überprüfen?', 'Sie haben %ld Dokumente mit ungesicherten Änderungen. Möchten Sie sie vor dem Beenden überprüfen?', 'Wenn Sie Ihre Änderungen nicht überprüfen, gehen sie verloren.', 'Änderungen überprüfen…'),
  'it.lproj':        ('Esci senza salvare', 'Hai un documento con modifiche non salvate. Vuoi controllarlo prima di uscire?', 'Hai %ld documenti con modifiche non salvate. Vuoi controllarli prima di uscire?', 'Se non controlli le modifiche, andranno perse.', 'Controlla modifiche…'),
  'ja-JP.lproj':     ('保存せずに終了', '保存されていない変更がある書類が 1 つあります。終了する前に確認しますか？', '保存されていない変更がある書類が %ld 個あります。終了する前に確認しますか？', '変更を確認しない場合、変更内容は失われます。', '変更内容を確認…'),
  'zh-Hans-CN.lproj':('不保存并退出', '有 1 个文档包含未保存的更改。是否要在退出前检查？', '有 %ld 个文档包含未保存的更改。是否要在退出前检查？', '如果不检查更改，这些更改将会丢失。', '检查更改…'),
  'zh-Hant-TW.lproj':('不儲存並結束', '有 1 份文件包含未儲存的變更。是否要在結束前檢查？', '有 %ld 份文件包含未儲存的變更。是否要在結束前檢查？', '如果不檢查變更，這些變更將會遺失。', '檢查變更…'),
}
KEYS = ['Quit Without Saving',
        'You have a document with unsaved changes. Do you want to review it before quitting?',
        'You have %ld documents with unsaved changes. Do you want to review them before quitting?',
        "If you don't review your changes, they will be lost.",
        'Review Changes…']
for lproj, vals in T.items():
    p = lproj + '/Localizable.strings'
    s = open(p, encoding='utf-8').read()
    if 'SCRIVAR-QUIT' in s:
        print(p + ': translations present'); continue
    block = '\n/* SCRIVAR-QUIT: quit-with-unsaved-documents dialog (scrivar-rebrand/fix-quit-dialog.sh) */\n'
    for k, v in zip(KEYS, vals):
        block += '"%s" = "%s";\n' % (k.replace('"', '\\"'), v.replace('"', '\\"'))
    open(p, 'w', encoding='utf-8').write(s.rstrip('\n') + '\n' + block)
    print(p + ': translations added')
PY
for f in AppDelegate.mm Code/Controllers/Common/ASCCommonViewController.mm; do
  grep -q 'SCRIVAR-QUIT' "$f" || { echo "ERROR: $f not patched"; exit 1; }
  ! grep -q 'Delete and Quit", nil)' "$f" || { echo "ERROR: $f still has Delete and Quit"; exit 1; }
done
for l in fr es de it ja-JP zh-Hans-CN zh-Hant-TW; do plutil -lint "$l.lproj/Localizable.strings" >/dev/null || { echo "ERROR: $l strings invalid"; exit 1; }; done
echo "fix-quit-dialog done."
