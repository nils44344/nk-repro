import json, threading, openai
from http.server import BaseHTTPRequestHandler, HTTPServer
hits = []
class H(BaseHTTPRequestHandler):
    def do_POST(self):
        self.rfile.read(int(self.headers.get("content-length") or 0)); hits.append(self.path)
        out = json.dumps({"id": "c1", "object": "chat.completion", "created": 0, "model": "m", "choices": [{"index": 0, "finish_reason": "stop", "message": {"role": "assistant", "content": "local"}}]}).encode()
        self.send_response(200); self.send_header("content-type", "application/json"); self.send_header("content-length", str(len(out))); self.end_headers(); self.wfile.write(out)
    def log_message(self, *a): pass
srv = HTTPServer(("127.0.0.1", 0), H); threading.Thread(target=srv.serve_forever, daemon=True).start()
openai.api_key = "sk-test"; openai.max_retries = 0
openai.api_base = f"http://127.0.0.1:{srv.server_port}/v1"
try: print("api_base:", openai.chat.completions.create(model="m", messages=[{"role": "user", "content": "hi"}]).choices[0].message.content, hits)
except Exception as e: print("api_base:", type(e).__name__, str(e)[:120], "local hits:", hits)
openai.base_url = f"http://127.0.0.1:{srv.server_port}/v1/"
try: print("base_url:", openai.chat.completions.create(model="m", messages=[{"role": "user", "content": "hi"}]).choices[0].message.content, hits)
except Exception as e: print("base_url:", type(e).__name__, str(e)[:120], hits)
