#!/bin/bash
# Scrivar Office rebrand — start-page "create" tiles fit the window (v1.0.14).
#
# Upstream's create row is four fixed 172x172 tiles with 32px gaps (784px) in a
# horizontally scrolling strip. At Scrivar Office's default window size the
# content column is narrower than that, so the 4th tile (PDF — the product's
# headline differentiator) sat half-hidden behind a sideways scrollbar.
#
# Fix: tiles share the row (flex 1 1 0) between 112px and 172px wide, stay
# square (aspect-ratio), and the 108x100 icons scale with them (the sprite
# symbols carry viewBox="0 0 108 100", so a percentage width scales cleanly).
# Gaps shrink with the viewport; below 840px the tiles go 2x2. At full size
# nothing changes. upstream's overflow-x:auto stays as a last resort.
#
# Run order: independent of the other loginpage sweeps (idempotent, marker
# guarded). Rebuild the loginpage (grunt in common/loginpage/build) after —
# NO C++ rebuild needed.
set -euo pipefail
cd "$(dirname "$0")/../common/loginpage"

python3 - <<'PY'
p = 'src/css/component.less'
s = open(p).read()
if 'SCRIVAR-TILES' in s:
    print('component.less: create tiles already fit')
    raise SystemExit(0)
anchor = "/**/\n.margin-left(@value) {"
if anchor not in s:
    raise SystemExit('ERROR: component.less anchor (.margin-left mixin) not found')
block = """// SCRIVAR-TILES begin (v1.0.14): the create row fits the window instead of
// scrolling sideways — see scrivar-rebrand/fit-create-tiles.sh.
.document-creation-grid {
    gap: clamp(12px, 2vw, 32px);
}

.document-creation-item {
    flex: 1 1 0;
    width: auto;
    min-width: 112px;
    max-width: 172px;
    height: auto;
    aspect-ratio: 1 / 1;
    padding: 24px 8px 16px;

    .icon {
        width: 100%;
        max-width: 108px;
        height: auto;
        aspect-ratio: 108 / 100;
    }
}

// Narrow windows (the main window can shrink to 518pt): four tiles can't
// share one row, so lay them out 2x2 and let the strip grow vertically
// (upstream's overflow-y:hidden + fixed min-height would clip the 2nd row).
@media (max-width: 840px) {
    // `html` prefix: styles.less compiles AFTER this file and sets the
    // same ID's overflow-y/min-height, so equal specificity would lose.
    html #area-document-creation-grid {
        overflow-y: visible;
        min-height: 0;
    }

    .document-creation-grid {
        display: grid;
        grid-template-columns: repeat(2, minmax(112px, 150px));
        justify-content: start;
    }

    .document-creation-item {
        max-width: none;
    }
}
// SCRIVAR-TILES end

"""
s = s.replace(anchor, block + anchor, 1)
open(p, 'w').write(s)
print('component.less: create tiles now fit the window')
PY
grep -q 'SCRIVAR-TILES' src/css/component.less || { echo "ERROR: tiles patch failed"; exit 1; }
echo "fit-create-tiles done."
