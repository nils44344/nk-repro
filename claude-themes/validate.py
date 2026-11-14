"""Checks every theme in themes/ against the token list in the official Claude Code docs (terminal-config, 'Create a custom theme')
and measures WCAG contrast of the readable tokens against a NOMINAL terminal background (Claude Code themes cannot set the terminal's own background).
Run: python validate.py"""
import json,glob,os,re,sys
DOC_TOKENS=set("""claude text inverseText inactive subtle suggestion permission remember success error warning merged promptBorder planMode autoAccept bashBorder ide fastMode effortUltra
diffAdded diffRemoved diffAddedDimmed diffRemovedDimmed diffAddedWord diffRemovedWord userMessageBackground userMessageBackgroundHover bashMessageBackgroundColor memoryBackgroundColor selectionBg composerSidebarBackground
rate_limit_fill rate_limit_empty briefLabelYou briefLabelClaude claudeShimmer warningShimmer permissionShimmer promptBorderShimmer inactiveShimmer fastModeShimmer""".split())
BASES={"dark","light","dark-daltonized","light-daltonized","dark-ansi","light-ansi"}
READ=["text","claude","suggestion","permission","success","error","warning","planMode","autoAccept","bashBorder"]
def lum(h):
    h=h.lstrip('#'); r,g,b=[int(h[i:i+2],16)/255 for i in (0,2,4)]
    f=lambda c:c/12.92 if c<=0.03928 else ((c+0.055)/1.055)**2.4
    return 0.2126*f(r)+0.7152*f(g)+0.0722*f(b)
def cr(a,b):
    la,lb=sorted((lum(a),lum(b)),reverse=True); return (la+0.05)/(lb+0.05)
bgs=json.load(open('nominal-backgrounds.json')); bad=0
for f in sorted(glob.glob('themes/*.json')):
    slug=os.path.basename(f)[:-5]; t=json.load(open(f)); o=t['overrides']
    assert set(t)<= {'name','base','overrides'}, slug
    assert t['base'] in BASES, slug
    unk=[k for k in o if k not in DOC_TOKENS]; badc=[k for k,v in o.items() if not re.fullmatch(r'#[0-9a-fA-F]{6}',v)]
    low=[(k,round(cr(o[k],bgs[slug]),1)) for k in READ if k in o and cr(o[k],bgs[slug])<4.5]
    text=round(cr(o['text'],bgs[slug]),1)
    print(f"{slug:18} tokens {len(o):2}  unknown {unk}  bad colours {badc}  text contrast {text}:1  below 4.5: {low}")
    bad+=len(unk)+len(badc)+len(low)
sys.exit(1 if bad else 0)
