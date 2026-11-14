"""Writes the data file the gallery page on nilaykabariya.blog is built from: themes + meta + checks.
Usage: python build_gallery_data.py <path to src/data/themes.json> <comma list of theme slugs seen in the real /theme picker on 2.1.325>
The order below is the display order: older themes first, newest batch last."""
import json, os, sys, glob
H = os.path.dirname(os.path.abspath(__file__))
out_path = sys.argv[1]
meta = json.load(open(os.path.join(H, 'themes-meta.json'))); chk = json.load(open(os.path.join(H, 'checks.json')))
FIVE = {'chai-at-midnight', 'monsoon-surat', 'paper-lantern', 'terminal-mango', 'kite-festival'}  # also seen listed in 2.1.319 on the owner's terminal
BATCH = int(sys.argv[2]) if len(sys.argv) > 2 else 1
order_file = os.path.join(H, 'display-order.json')
order = json.load(open(order_file)) if os.path.exists(order_file) else []
slugs = [os.path.basename(f)[:-5] for f in glob.glob(os.path.join(H, 'themes', '*.json'))]
for s in sorted(slugs):  # anything new goes to the end, alphabetical
    if s not in order: order.append(s)
order = [s for s in order if s in slugs]
json.dump(order, open(order_file, 'w'), indent=1)
themes = []
for s in order:
    t = json.load(open(os.path.join(H, 'themes', s + '.json'))); m = meta[s]; c = chk[s]
    themes.append({"slug": s, "name": t["name"], "base": t["base"], "bg": m["bg"], "moods": m["moods"], "collection": m["collection"], "live": m.get("live", False), "idea": m["idea"],
                   "checks": {k: c[k] for k in ("textContrast", "minReadable", "diffText", "statusDeltaE", "addedRemovedDeltaE", "cvdDeltaE", "cvdSafeClaim")},
                   "listed": ["2.1.319", "2.1.325"] if s in FIVE else ["2.1.325"], "overrides": t["overrides"]})
json.dump({"themes": themes, "testedDate": "2026-11-14", "batch": BATCH}, open(out_path, 'w'), indent=1)
print(len(themes), 'themes ->', out_path)
