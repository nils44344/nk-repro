import json, threading, sys, importlib
from http.server import BaseHTTPRequestHandler, HTTPServer
seen = []
class P(BaseHTTPRequestHandler):  # records requests that arrive through it as a proxy
    def do_GET(self): self.do_POST()
    def do_POST(self):
        self.rfile.read(int(self.headers.get("content-length") or 0)); seen.append(self.path)
        out = json.dumps({"id": "resp_1", "object": "response", "created_at": 0, "status": "completed", "model": "m",
            "data": [], "output": [], "parallel_tool_calls": True, "tool_choice": "auto", "tools": []}).encode()
        self.send_response(200); self.send_header("content-type", "application/json")
        self.send_header("content-length", str(len(out))); self.end_headers(); self.wfile.write(out)
    def log_message(self, *a): pass
srv = HTTPServer(("127.0.0.1", 0), P); threading.Thread(target=srv.serve_forever, daemon=True).start()
PROXY = f"http://127.0.0.1:{srv.server_port}"
def run(name, fn):
    try: r = fn(); print(f"{name}: OK {r if r is not None else ''}")
    except Exception as e: print(f"{name}: {type(e).__name__}: {e}")
def has(m):
    try: return importlib.import_module(m)
    except ImportError: return None
httpx, httpx2, openai, anthropic = (has(m) for m in ("httpx", "httpx2", "openai", "anthropic"))
print("python", sys.version.split()[0], *(f"{m.__name__} {m.__version__}" for m in (httpx, httpx2, openai, anthropic) if m))
if openai:
    run("openai.OpenAI()", lambda: openai.OpenAI(api_key="sk-x") and "constructed")
    run("openai.OpenAI(proxies=)", lambda: openai.OpenAI(api_key="sk-x", proxies=PROXY))
    D = getattr(openai, "DefaultHttpxClient", None)
    if D:
        def via():
            c = openai.OpenAI(api_key="sk-x", base_url="http://api.test/v1", max_retries=0, http_client=D(proxy=PROXY))
            c.models.list(); return f"proxy saw {seen[-1]}"
        run("DefaultHttpxClient(proxy=)", via)
        run("DefaultHttpxClient(proxies=)", lambda: D(proxies=PROXY))
    if httpx:
        run("OpenAI(http_client=httpx.Client())", lambda: openai.OpenAI(api_key="sk-x", http_client=httpx.Client()) and "constructed")
if anthropic:
    run("anthropic.Anthropic()", lambda: anthropic.Anthropic(api_key="sk-x") and "constructed")
for mod in (httpx, httpx2):
    if not mod: continue
    n = mod.__name__
    run(f"{n}.Client(proxies=)", lambda: mod.Client(proxies=PROXY))
    run(f"{n}.post(proxies=)", lambda: mod.post("http://api.test/v1/x", proxies=PROXY))
    run(f"{n}.Client(proxy=)", lambda: mod.Client(proxy=PROXY).post("http://api.test/v1/x") and f"proxy saw {seen[-1]}")
    def mounts():
        c = mod.Client(mounts={"http://": mod.HTTPTransport(proxy=PROXY)}); c.post("http://api.test/v1/m"); return f"proxy saw {seen[-1]}"
    run(f"{n}.Client(mounts=)", mounts)
if openai and httpx:
    def own():
        c = openai.OpenAI(api_key="sk-x", base_url="http://api.test/v1", max_retries=0, http_client=httpx.Client(proxy=PROXY))
        c.models.list(); return f"proxy saw {seen[-1]}"
    run("OpenAI(http_client=httpx.Client(proxy=)) request", own)
