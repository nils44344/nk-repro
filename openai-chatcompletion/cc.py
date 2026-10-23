import json, threading, sys
from http.server import BaseHTTPRequestHandler, HTTPServer
seen = []
class H(BaseHTTPRequestHandler):
    def do_GET(self): self.do_POST()
    def do_POST(self):
        b = self.rfile.read(int(self.headers.get("content-length") or 0)); seen.append((self.path, self.headers.get("authorization", "")[:12]))
        out = json.dumps({"id": "c1", "object": "chat.completion", "created": 0, "model": "gpt-4.1-mini",
            "choices": [{"index": 0, "finish_reason": "stop", "message": {"role": "assistant", "content": "hi"}}],
            "data": [{"object": "embedding", "index": 0, "embedding": [0.1]}], "usage": {"prompt_tokens": 1, "completion_tokens": 1, "total_tokens": 2}}).encode()
        self.send_response(200); self.send_header("content-type", "application/json"); self.send_header("content-length", str(len(out))); self.end_headers(); self.wfile.write(out)
    def log_message(self, *a): pass
srv = HTTPServer(("127.0.0.1", 0), H); threading.Thread(target=srv.serve_forever, daemon=True).start()
BASE = f"http://127.0.0.1:{srv.server_port}/v1"
import openai
print("python", sys.version.split()[0], "openai", openai.__version__)
def run(name, fn):
    try: r = fn(); print(f"{name}: OK {r if r is not None else ''}")
    except Exception as e: print(f"{name}: {type(e).__module__}.{type(e).__name__}: {str(e)[:400]}")
M = [{"role": "user", "content": "hi"}]
openai.api_key = "sk-test"
if hasattr(openai, "api_base"): openai.api_base = BASE
else: openai.base_url = BASE + "/"
run("openai.ChatCompletion.create", lambda: openai.ChatCompletion.create(model="gpt-4.1-mini", messages=M)["choices"][0]["message"]["content"])
run("openai.Completion.create", lambda: openai.Completion.create(model="x", prompt="hi") and "sent")
run("openai.Embedding.create", lambda: openai.Embedding.create(model="x", input="hi") and "sent")
run("openai.error.RateLimitError", lambda: openai.error.RateLimitError)
run("openai.RateLimitError", lambda: openai.RateLimitError.__name__)
run("module-level openai.chat.completions.create", lambda: (openai.chat.completions.create(model="gpt-4.1-mini", messages=M).choices[0].message.content, seen[-1]))
def client():
    c = openai.OpenAI(api_key="sk-test", base_url=BASE)
    r = c.chat.completions.create(model="gpt-4.1-mini", messages=M); return (r.choices[0].message.content, seen[-1])
run("OpenAI().chat.completions.create", client)
run("client.ChatCompletion", lambda: openai.OpenAI(api_key="sk-test").ChatCompletion)
run("r['choices'] on new response", lambda: openai.OpenAI(api_key="sk-test", base_url=BASE).chat.completions.create(model="gpt-4.1-mini", messages=M)["choices"])
