#!/bin/bash
# httpx -> httpx2 across the Anthropic, Hugging Face and Google GenAI Python SDKs (9 Nov 2026).
# (a) does the SDK still install httpx? (b) does code that did `import httpx` (transitively available) break?
# (c) does respx (which patches httpx) intercept the SDK's requests? No API keys: a black-holed base URL proves it.
set +e
W=${W:-$(pwd)/work}; rm -rf "$W"; mkdir -p "$W"; cd "$W" || exit 1
PY=${PY:-python}
echo "== $(date -u +%F) $($PY -V)"
probe() { # $1 label, $2 pip specs
  rm -rf v && $PY -m venv v && v/bin/pip install -q --disable-pip-version-check $2 respx >/dev/null 2>pip.err || { echo "$1 | install failed: $(tail -1 pip.err)"; return; }
  v/bin/python - "$1" <<'PY'
import sys, importlib.util as u, importlib.metadata as md
label = sys.argv[1]
def ver(n):
    try: return md.version(n)
    except Exception: return None
print(f"### {label}")
print("   installed: httpx", ver("httpx"), "| httpx2", ver("httpx2"), "| respx", ver("respx"))
try:
    import httpx; print("   import httpx: ok")
except Exception as e: print("   import httpx:", type(e).__name__, e)
PY
}
probe "anthropic latest" "anthropic"
probe "anthropic<1" "anthropic<1"
probe "huggingface_hub latest" "huggingface_hub"
probe "huggingface_hub<2" "huggingface_hub<2"
probe "google-genai latest" "google-genai"
probe "google-genai<3" "google-genai<3"
echo "### respx vs each SDK's client (base URL points at a closed port; a mocked call returns 200, an unmocked one fails to connect)"
rm -rf v && $PY -m venv v && v/bin/pip install -q anthropic google-genai respx >/dev/null 2>&1
v/bin/python - <<'PY'
import respx, httpx, importlib.metadata as md
print("   anthropic", md.version("anthropic"), "| google-genai", md.version("google-genai"), "| respx", md.version("respx"))
with respx.mock(assert_all_called=False) as m:
    m.post("http://127.0.0.1:9/v1/messages").mock(return_value=httpx.Response(200, json={"id":"x","type":"message","role":"assistant","model":"m","content":[{"type":"text","text":"mocked"}],"stop_reason":"end_turn","stop_sequence":None,"usage":{"input_tokens":1,"output_tokens":1}}))
    import anthropic
    try:
        r = anthropic.Anthropic(api_key="x", base_url="http://127.0.0.1:9", max_retries=0).messages.create(model="m", max_tokens=1, messages=[{"role":"user","content":"hi"}])
        print("   anthropic + respx:", "MOCKED ->", r.content[0].text)
    except Exception as e:
        print("   anthropic + respx: NOT mocked ->", type(e).__name__, str(e)[:100])
PY
echo "== done"
