"""Checks every theme in themes/ and writes checks.json (the numbers the gallery shows).
1. Format: only the three fields name/base/overrides; base is a documented value; every token is on the official list; every colour is #rrggbb.
2. Contrast (WCAG) of every readable token (text, accent, status, mode colours) against the background the palette was designed for.
   A Claude Code theme cannot set the terminal's own background, so each theme names its design background in themes-meta.json.
3. Text on the diff backgrounds (added and removed lines) is readable (4.5:1).
4. Success, error and warning are clearly different colours (CIE76 delta-E, normal vision), and added vs removed line backgrounds differ.
5. The same pairwise delta-E after simulating deuteranopia and protanopia (Machado 2009, full severity). Reported for every theme; only
   themes marked "cvd" in the meta are required to pass it.
Run: python build_themes.py && python validate.py   (exit code 1 on any failure)"""
import json, glob, os, re, sys, itertools, math
H = os.path.dirname(os.path.abspath(__file__))
DOC = set("""claude text inverseText inactive subtle suggestion permission remember success error warning merged promptBorder planMode autoAccept bashBorder ide fastMode effortUltra
diffAdded diffRemoved diffAddedDimmed diffRemovedDimmed diffAddedWord diffRemovedWord userMessageBackground userMessageBackgroundHover bashMessageBackgroundColor memoryBackgroundColor selectionBg composerSidebarBackground
rate_limit_fill rate_limit_empty briefLabelYou briefLabelClaude claudeShimmer warningShimmer permissionShimmer promptBorderShimmer inactiveShimmer fastModeShimmer""".split())
BASES = {"dark", "light", "dark-daltonized", "light-daltonized", "dark-ansi", "light-ansi"}
READ = ["text", "claude", "suggestion", "permission", "success", "error", "warning", "planMode", "autoAccept", "bashBorder"]

def rgb(h): h = h.lstrip('#'); return [int(h[i:i+2], 16) for i in (0, 2, 4)]
def lin(c): c /= 255; return c / 12.92 if c <= 0.04045 else ((c + 0.055) / 1.055) ** 2.4
def lum(h): r, g, b = [lin(v) for v in rgb(h)]; return 0.2126 * r + 0.7152 * g + 0.0722 * b
def cr(a, b): la, lb = sorted((lum(a), lum(b)), reverse=True); return (la + 0.05) / (lb + 0.05)
def lab(lr):
    r, g, b = lr
    x = (0.4124 * r + 0.3576 * g + 0.1805 * b) / 0.95047; y = 0.2126 * r + 0.7152 * g + 0.0722 * b; z = (0.0193 * r + 0.1192 * g + 0.9505 * b) / 1.08883
    f = lambda t: t ** (1 / 3) if t > 0.008856 else 7.787 * t + 16 / 116
    return (116 * f(y) - 16, 500 * (f(x) - f(y)), 200 * (f(y) - f(z)))
def de(a, b): return math.dist(a, b)
def labof(h, m=None):
    l = [lin(v) for v in rgb(h)]
    if m: l = [max(0, min(1, sum(m[i][j] * l[j] for j in range(3)))) for i in range(3)]
    return lab(l)
DEUT = [[0.367322, 0.860646, -0.228968], [0.280085, 0.672501, 0.047413], [-0.011820, 0.042940, 0.968881]]
PROT = [[0.152286, 1.052583, -0.204868], [0.114503, 0.786281, 0.099216], [-0.003882, -0.048116, 1.051998]]
def min_de(cols, m=None): return min(de(labof(a, m), labof(b, m)) for a, b in itertools.combinations(cols, 2))

meta = json.load(open(os.path.join(H, 'themes-meta.json'))); out = {}; fails = 0
for f in sorted(glob.glob(os.path.join(H, 'themes', '*.json'))):
    slug = os.path.basename(f)[:-5]; t = json.load(open(f)); o = t['overrides']; m = meta[slug]; bg = m['bg']; prob = []
    if set(t) - {'name', 'base', 'overrides'}: prob.append('extra fields')
    if t['base'] not in BASES: prob.append('bad base')
    unk = [k for k in o if k not in DOC]; bad = [k for k, v in o.items() if not re.fullmatch(r'#[0-9a-fA-F]{6}', v)]
    if unk: prob.append(f'unknown tokens {unk}')
    if bad: prob.append(f'bad colours {bad}')
    min_read = min(cr(o[k], bg) for k in READ)
    if min_read < m.get('minRead', 4.5) - 1e-6: prob.append(f'readable token contrast {min_read:.2f}')
    diff_text = min(cr(o['text'], o['diffAdded']), cr(o['text'], o['diffRemoved']))
    if diff_text < 4.5: prob.append(f'text on diff backgrounds {diff_text:.2f}')
    stat = [o['success'], o['error'], o['warning']]
    status_de = min_de(stat); addrem_de = de(labof(o['diffAdded']), labof(o['diffRemoved']))
    if status_de < 25: prob.append(f'success/error/warning too close (dE {status_de:.0f})')
    if addrem_de < 8: prob.append(f'added/removed backgrounds too close (dE {addrem_de:.0f})')
    cvd = min(min_de(stat, DEUT), min_de(stat, PROT))
    if m.get('cvd') and cvd < 20: prob.append(f'colour-blind check failed (dE {cvd:.0f})')
    out[slug] = {"tokens": len(o), "textContrast": round(cr(o['text'], bg), 1), "minReadable": round(min_read, 1), "diffText": round(diff_text, 1),
                 "statusDeltaE": round(status_de), "addedRemovedDeltaE": round(addrem_de), "cvdDeltaE": round(cvd), "cvdSafeClaim": bool(m.get('cvd')), "problems": prob}
    print(f"{slug:22} tokens {len(o)} text {out[slug]['textContrast']:>4}:1 min {out[slug]['minReadable']:>4}:1 diff-text {out[slug]['diffText']:>4}:1 status dE {out[slug]['statusDeltaE']:>3} add/rem dE {out[slug]['addedRemovedDeltaE']:>3} cvd dE {out[slug]['cvdDeltaE']:>3} {'FAIL ' + str(prob) if prob else 'ok'}")
    fails += len(prob)
json.dump(out, open(os.path.join(H, 'checks.json'), 'w'), indent=1)
print(len(out), 'themes,', fails, 'problems')
sys.exit(1 if fails else 0)
