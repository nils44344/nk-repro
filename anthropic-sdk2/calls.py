import json, threading, traceback, sys
from http.server import BaseHTTPRequestHandler, HTTPServer
import anthropic

seen = []
class H(BaseHTTPRequestHandler):
    def do_POST(self):
        body = self.rfile.read(int(self.headers.get("content-length", 0)))
        seen.append({k.lower(): v for k, v in self.headers.items()} | {"_body": body.decode()})
        out = json.dumps({"id": "msg_1", "type": "message", "role": "assistant", "model": "claude-opus-5-5",
            "content": [{"type": "text", "text": "hi"}], "stop_reason": "end_turn", "stop_sequence": None,
            "usage": {"input_tokens": 1, "output_tokens": 1}}).encode()
        self.send_response(200); self.send_header("content-type", "application/json")
        self.send_header("content-length", str(len(out))); self.end_headers(); self.wfile.write(out)
    def log_message(self, *a): pass

srv = HTTPServer(("127.0.0.1", 0), H); threading.Thread(target=srv.serve_forever, daemon=True).start()
base = f"http://127.0.0.1:{srv.server_port}"
print("anthropic", anthropic.__version__, "python", sys.version.split()[0])

def run(name, fn):
    print(f"\n## {name}")
    try:
        r = fn(); print("OK", r if r is not None else "")
    except Exception as e:
        print(f"{type(e).__name__}: {e}")

c = anthropic.Anthropic(api_key="sk-ant-fake", base_url=base, max_retries=0)
msgs = [{"role": "user", "content": "hi"}]
M = "claude-opus-5-5"

def plain():
    c.messages.create(model=M, max_tokens=10, messages=msgs)
    h = seen[-1]
    return {k: (h.get(k) or "")[:22] for k in ("x-api-key", "authorization", "anthropic-version")}
run("plain create, headers sent", plain)
run("temperature=0.2", lambda: c.messages.create(model=M, max_tokens=10, messages=msgs, temperature=0.2) and json.loads(seen[-1]["_body"]).get("temperature"))
run("top_p=0.9", lambda: c.messages.create(model=M, max_tokens=10, messages=msgs, top_p=0.9) and "sent")
run("top_k=5", lambda: c.messages.create(model=M, max_tokens=10, messages=msgs, top_k=5) and "sent")
run("extra_body temperature", lambda: c.messages.create(model=M, max_tokens=10, messages=msgs, extra_body={"temperature": 0.2}) and json.loads(seen[-1]["_body"]).get("temperature"))
def mp():
    from anthropic.types import MessageParam
    return MessageParam(role="user", content="hi")
run("MessageParam(role=..., content=...)", mp)
run("Anthropic(api_key=..., auth_token=...)", lambda: anthropic.Anthropic(api_key="sk-ant-fake", auth_token="tok", base_url=base) and "constructed")
run("client.completions", lambda: type(c.completions).__name__)
def stream():
    with c.messages.stream(model=M, max_tokens=10, messages=msgs, temperature=0.5) as s:
        pass
run("messages.stream(temperature=0.5)", stream)
run("count_tokens(temperature)", lambda: c.messages.count_tokens(model=M, messages=msgs, temperature=0.2))
