"""Builds the generated themes in themes/*.json from compact palette specs, and writes themes-meta.json (mood tags, collection, the idea behind
each theme, and every measured check). Hand-written themes (the first five) keep their own JSON; they are listed here only for their meta.
Run: python build_themes.py && python validate.py
Every colour a theme uses is derived from the spec below, so the checks in validate.py apply the same way to all of them."""
import json, os, re
import sys; sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
from batch3_specs import B3

HERE = os.path.dirname(os.path.abspath(__file__))

def h2r(h): h = h.lstrip('#'); return tuple(int(h[i:i+2], 16) for i in (0, 2, 4))
def r2h(c): return '#%02x%02x%02x' % tuple(max(0, min(255, round(v))) for v in c)
def mix(a, b, t): a, b = h2r(a), h2r(b); return r2h([x + (y - x) * t for x, y in zip(a, b)])
def lin(c): c /= 255; return c / 12.92 if c <= 0.04045 else ((c + 0.055) / 1.055) ** 2.4
def lum(h): r, g, b = h2r(h); return 0.2126 * lin(r) + 0.7152 * lin(g) + 0.0722 * lin(b)
def cr(a, b): la, lb = sorted((lum(a), lum(b)), reverse=True); return (la + 0.05) / (lb + 0.05)
def fit(color, bg, minc):
    """Move `color` toward white (dark bg) or black (light bg) until it has `minc`:1 contrast with bg."""
    target = '#ffffff' if lum(bg) < 0.4 else '#000000'
    t = 0.0
    while cr(color, bg) < minc and t < 1:
        t += 0.02; c = mix(color, target, t)
        if cr(c, bg) >= minc: return c
    return color if cr(color, bg) >= minc else target

# (slug, name, base, bg, fg, accent, ok, bad, warn, plan, auto, sugg, perm, bash, moods, collection, idea, extra)
S = [
 ('rasgulla-at-dawn','Rasgulla at Dawn','light','#fff8ec','#3b2a2a','#c2477a','#4f8a4b','#c0392b','#b7791f','#2a7f86','#8a5ac2','#b8651b','#b7791f','#c2477a',['Soft','Warm','Light'],'Food and drink','Syrup gold, rose water and cream: a sweet shop opening at first light.',{}),
 ('lavender-field-5pm','Lavender Field, 5 pm','light','#f6f1fb','#2f2540','#7c4dcc','#3f7d58','#b83a56','#9a6a12','#2c7a8a','#a24fb0','#5b6fd1','#9a6a12','#b83a56',['Soft','Calm','Cool','Light'],'Places and hours','Pastel lilac with sage and dusk-blue: long shadows over a field, nothing shouting.',{}),
 ('candy-floss-arcade','Candy Floss Arcade','light','#fff5fb','#2a1f3d','#e0248a','#12a05c','#e03131','#b86e00','#1c7ed6','#9c36b5','#f06595','#d9480f','#e0248a',['Playful','Bold','Light'],'Machines and arcades','Spun sugar pink and bubble-gum blue on a fairground-bright white.',{}),
 ('jewel-box','Jewel Box','dark','#0b1f1a','#e8f3ee','#2ee6a6','#5fe3a1','#ff4d6d','#ffc145','#5b8cff','#b583ff','#6fd6ff','#ffc145','#ff7a90',['Bold','Cool','Dark'],'Materials','Emerald velvet lining with ruby, sapphire, amber and amethyst set into it.',{}),
 ('rose-quartz-notebook','Rose Quartz Notebook','light','#fbf3f3','#3a2a30','#b4506a','#4d7f5f','#b3363f','#8f6a1d','#3f7d86','#7b5aa6','#a0526b','#8f6a1d','#b4506a',['Soft','Calm','Light'],'Materials','A stone-pink paper notebook with a dark-plum pen and one gold-edged page.',{}),
 ('neon-rickshaw','Neon Rickshaw','dark','#0a0a12','#f5f5ff','#ff2fa3','#39ff88','#ff4d4d','#ffe14d','#2fe6ff','#b36bff','#2fe6ff','#ffe14d','#ff9a2f',['Bold','Playful','Dark'],'Machines and arcades','A night-market auto rickshaw wired with tube lights, magenta first.',{'live':True}),
 ('steel-mill-4am','Steel Mill, 4 am','dark','#12171c','#d9e0e6','#ff8a3d','#7fc8a0','#ff6b5e','#f2c14e','#6fb4d8','#a7a9e0','#8fb8d6','#f2c14e','#ff8a3d',['Cool','Calm','Dark'],'Places and hours','Cold rolled steel greys in the dark, and sparks of orange where metal meets metal.',{}),
 ('pit-lane','Pit Lane','dark','#0d0d0d','#f2f2f2','#e10600','#2fd16a','#ff4638','#ffd60a','#4aa8ff','#f2f2f2','#ffd60a','#ffd60a','#ff4638',['Bold','Dark'],'Machines and arcades','Tarmac black, race-flag red and signal yellow: everything reads at a glance at speed.',{}),
 ('bandhani-night','Bandhani Night','dark','#101640','#f3ecda','#ff6b57','#8fd9a8','#ff7a7a','#ffd166','#7fc4ff','#e7a8ff','#ffd166','#ffd166','#ff6b57',['Warm','Playful','Dark'],'Textiles','Tie-dyed indigo cloth: dye-red and saffron dots on a deep night-blue ground.',{}),
 ('sakura-night','Sakura Night','dark','#1b1220','#f1e4ee','#ff9fc0','#9ad9b0','#ff7f8f','#f2d28b','#8fd0e0','#c8a2ff','#ffc0d6','#f2d28b','#ff9fc0',['Soft','Calm','Dark'],'Places and hours','Blossom pink falling on a plum-dark evening.',{}),
 ('low-glare-night','Low-Glare Night','dark','#14110e','#cdbfae','#c9964f','#8da878','#c97a6a','#c9a54f','#8a9f9a','#a58fb0','#b79a6a','#c9a54f','#c9843f',['Calm','Warm','Dark'],'Made for a need','Made for late hours: warm browns and muted tones with almost no blue light, so the screen does not glare.',{'min_text':7.0}),
 ('high-contrast-chalk','High-Contrast Chalk','dark','#000000','#ffffff','#ffff00','#00ff7f','#ff5555','#ffcc00','#00e5ff','#ff80ff','#00e5ff','#ffcc00','#ff9900',['Bold','Dark'],'Made for a need','Pure black and white with bright chalk colours: every readable colour is at least 7:1.',{'min_read':7.0,'min_text':7.0}),
 ('safe-signals','Safe Signals','dark','#14181d','#eceff3','#56b4e9','#2bbf94','#f07a35','#f0e442','#56b4e9','#cc79a7','#56b4e9','#e69f00','#e69f00',['Calm','Cool','Dark'],'Made for a need','Built on the Okabe-Ito colour-blind-safe palette: success, error and warning stay apart under red-green colour blindness, and added and removed lines are blue and orange.',{'diffadd':'#56b4e9','diffrem':'#e69f00','cvd':True}),
 ('sea-glass-noon','Sea Glass, Noon','light','#f1faf8','#17353a','#0f8b8d','#2e8b57','#c0392b','#a8741a','#1d6fa5','#7a56b8','#0f8b8d','#a8741a','#c05a2b',['Cool','Calm','Light'],'Day and night','Daylight through a green glass bottle on a windowsill. The daytime half of a pair.',{}),
 ('sea-glass-midnight','Sea Glass, Midnight','dark','#07191d','#d6efec','#5fd6d0','#7fe0a0','#ff8070','#f2cf72','#6bb8f0','#b79cf0','#5fd6d0','#f2cf72','#ff9a70',['Cool','Calm','Dark'],'Day and night','The same bottle by moonlight. The night half of the pair, same hues, same roles.',{}),
 ('diwali-diya','Diwali Diya','dark','#220d0d','#fbeccd','#ffb400','#9be07a','#ff6a5a','#ffd25a','#7fd3c8','#ff8fb1','#ff9a3c','#ffd25a','#ff6a3c',['Warm','Bold','Dark'],'Festivals','A row of clay lamps in a dark maroon room: flame yellow, saffron and ember.',{'live':True}),
 ('holi-morning','Holi Morning','light','#fffdf7','#261c33','#d81b60','#00897b','#c62828','#b26a00','#1e88e5','#8e24aa','#f4511e','#ef6c00','#d81b60',['Playful','Bold','Light'],'Festivals','Powder colours thrown on a white morning: magenta, teal, blue and orange all at once.',{}),
 ('mogra-evening','Mogra Evening','light','#fbfaf3','#2c3a2e','#3f7d5a','#2f7d4f','#b23a48','#9a7414','#2b7a8a','#8a5ea8','#3f7d5a','#9a7414','#b2563a',['Soft','Calm','Light'],'Places and hours','Jasmine white and leaf green on a warm evening veranda.',{}),
 ('cricket-pitch','Cricket Pitch','light','#f7f6e9','#1f2d1c','#b3202a','#2e7d32','#c62828','#a06a00','#1565c0','#6a1b9a','#b3202a','#a06a00','#b3202a',['Playful','Bold','Light'],'Sports','Mown-grass cream, ball red and whites: a Sunday match.',{}),
 ('old-radio','Old Radio','dark','#1c1410','#e9d9bc','#e8a33d','#9bbf7a','#e0705a','#ecc25b','#7fb3b0','#c79ad0','#d9a066','#ecc25b','#e8793d',['Warm','Calm','Dark'],'Objects','A walnut cabinet, a glowing amber dial and cloth-speaker beige.',{}),
 ('mehendi-green','Mehendi Green','dark','#141c14','#e6e2cf','#d9703a','#9fcf7a','#ef7b63','#e5c15d','#6fbfa5','#c99fd6','#e0925a','#e5c15d','#d9703a',['Warm','Calm','Dark'],'Festivals','Fresh henna paste green, drying to terracotta.',{}),
 ('gulmohar-summer','Gulmohar Summer','light','#fffaf2','#33201a','#d6401f','#2f7d3a','#b3261e','#9c6500','#0b7a8a','#8e3ba8','#c9531c','#9c6500','#d6401f',['Bold','Warm','Light'],'Places and hours','Gulmohar blossom, orange-red over a hot white afternoon.',{}),
 ('aurora-night-train','Aurora Night Train','dark','#0a1020','#e6eefc','#5ef2c0','#66f2a8','#ff6b8a','#ffd36b','#6ab7ff','#c08bff','#5ef2c0','#ffd36b','#ff9a6b',['Cool','Playful','Dark'],'Places and hours','A night train through the north: green and violet light over deep blue.',{'live':True}),
 ('marble-and-brass','Marble and Brass','light','#f4f4f2','#25272b','#9a7424','#2f7a55','#b3362f','#8c6a12','#2a6f8c','#6f56a8','#2a6f8c','#8c6a12','#a05a2c',['Calm','Cool','Light'],'Materials','Cool grey marble with a brass accent: a quiet, formal light theme.',{}),
 ('ink-and-indigo','Ink and Indigo','light','#f5f2ea','#1b2250','#2b3a9c','#2c7a56','#b23a3a','#946a12','#1f6f95','#7a4aa0','#2b3a9c','#946a12','#b0502a',['Cool','Calm','Light'],'Textiles','Block-printed indigo on unbleached cotton.',{}),
] + B3

H = {  # the five hand-written themes: meta only
 'chai-at-midnight': (['Warm','Calm','Dark'],'Food and drink','Warm amber on cocoa, the colour of the last chai.'),
 'monsoon-surat': (['Cool','Calm','Dark'],'Places and hours','Rain-washed teals for long debugging evenings in Surat.'),
 'paper-lantern': (['Warm','Soft','Light'],'Festivals','Cream paper and a vermilion lantern: a light theme that does not burn your eyes.'),
 'terminal-mango': (['Bold','Warm','Dark'],'Machines and arcades','Hot mango on near-black: loud accent, quiet everything else.'),
 'kite-festival': (['Playful','Bold','Light'],'Festivals','Magenta, cyan and violet against a bright Uttarayan sky.'),
}
NOM = {'chai-at-midnight':'#16100c','monsoon-surat':'#0d1618','paper-lantern':'#faf5ea','terminal-mango':'#101010','kite-festival':'#fbfbff'}
READ = ["text","claude","suggestion","permission","success","error","warning","planMode","autoAccept","bashBorder"]

def build(spec):
    slug,name,base,bg,fg,acc,ok,bad,warn,plan,auto,sugg,perm,bash,moods,coll,idea,ex = spec
    dark = base == 'dark'
    minr = ex.get('min_read', 4.5)
    f = lambda c: fit(c, bg, minr)
    o = {}
    o['text'] = fit(fg, bg, ex.get('min_text', 4.5))
    o['claude'] = f(acc); o['claudeShimmer'] = mix(o['claude'], o['text'], 0.35)
    o['inactive'] = fit(mix(fg, bg, 0.45), bg, 4.5); o['subtle'] = mix(fg, bg, 0.62)
    o['suggestion'] = f(sugg); o['permission'] = f(perm)
    o['success'] = f(ok); o['error'] = f(bad); o['warning'] = f(warn)
    o['planMode'] = f(plan); o['autoAccept'] = f(auto); o['bashBorder'] = f(bash)
    o['promptBorder'] = mix(bg, acc, 0.4 if dark else 0.45)
    o['userMessageBackground'] = mix(bg, fg, 0.07 if dark else 0.05)
    o['selectionBg'] = mix(bg, acc, 0.3)
    a, r = ex.get('diffadd', ok), ex.get('diffrem', bad)
    o['diffAdded'] = mix(bg, a, 0.24); o['diffRemoved'] = mix(bg, r, 0.26)
    o['diffAddedDimmed'] = mix(bg, a, 0.13); o['diffRemovedDimmed'] = mix(bg, r, 0.14)
    o['diffAddedWord'] = mix(bg, a, 0.5); o['diffRemovedWord'] = mix(bg, r, 0.52)
    o['rate_limit_fill'] = o['claude']; o['rate_limit_empty'] = mix(bg, fg, 0.12)
    if ex.get('live'):
        o['warningShimmer'] = mix(o['warning'], o['text'], 0.5); o['permissionShimmer'] = mix(o['permission'], o['text'], 0.5)
        o['promptBorderShimmer'] = mix(o['promptBorder'], acc, 0.75); o['inactiveShimmer'] = mix(o['inactive'], o['text'], 0.5)
        o['fastModeShimmer'] = mix(o['planMode'], o['text'], 0.5)
    keys = ["claude","claudeShimmer","text","inactive","subtle","suggestion","permission","success","error","warning","promptBorder","planMode","autoAccept","bashBorder",
            "diffAdded","diffRemoved","diffAddedDimmed","diffRemovedDimmed","diffAddedWord","diffRemovedWord","userMessageBackground","selectionBg","rate_limit_fill","rate_limit_empty"]
    if ex.get('live'): keys = keys + ["warningShimmer", "permissionShimmer", "promptBorderShimmer", "inactiveShimmer", "fastModeShimmer"]
    return {"name": name, "base": base, "overrides": {k: o[k] for k in keys}}

meta = {}
for sp in S:
    t = build(sp)
    json.dump(t, open(os.path.join(HERE, 'themes', sp[0] + '.json'), 'w'), indent=2)
    meta[sp[0]] = {"bg": sp[3], "moods": sp[14], "collection": sp[15], "idea": sp[16], "cvd": bool(sp[17].get('cvd')), "live": bool(sp[17].get('live')), "minRead": sp[17].get('min_read', 4.5)}
for slug, (m, c, i) in H.items():
    meta[slug] = {"bg": NOM[slug], "moods": m, "collection": c, "idea": i, "cvd": False, "live": False, "minRead": 4.5}
json.dump(meta, open(os.path.join(HERE, 'themes-meta.json'), 'w'), indent=2)
print(len(meta), 'themes in meta;', len(S), 'generated')
