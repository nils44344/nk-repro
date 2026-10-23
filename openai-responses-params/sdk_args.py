import json, threading, sys
from http.server import BaseHTTPRequestHandler, HTTPServer
import openai

seen = []
class H(BaseHTTPRequestHandler):
    def do_POST(self):
        body = self.rfile.read(int(self.headers.get("content-length", 0)))
        seen.append(json.loads(body))
        out = json.dumps({"id": "resp_1", "object": "response", "created_at": 0, "status": "completed", "model": "gpt-5.5",
            "output": [], "parallel_tool_calls": True, "tool_choice": "auto", "tools": []}).encode()
        self.send_response(200); self.send_header("content-type", "application/json")
        self.send_header("content-length", str(len(out))); self.end_headers(); self.wfile.write(out)
    def log_message(self, *a): pass

srv = HTTPServer(("127.0.0.1", 0), H); threading.Thread(target=srv.serve_forever, daemon=True).start()
c = openai.OpenAI(api_key="sk-fake", base_url=f"http://127.0.0.1:{srv.server_port}/v1", max_retries=0)
print("openai", openai.__version__)
base = dict(model="gpt-5.5", input="hi")
cases = {
  "messages": dict(model="gpt-5.5", messages=[{"role": "user", "content": "hi"}]),
  "max_tokens": dict(base, max_tokens=50),
  "max_completion_tokens": dict(base, max_completion_tokens=50),
  "seed": dict(base, seed=1),
  "frequency_penalty": dict(base, frequency_penalty=0.5),
  "presence_penalty": dict(base, presence_penalty=0.5),
  "response_format": dict(base, response_format={"type": "json_object"}),
  "verbosity": dict(base, verbosity="low"),
  "reasoning_effort": dict(base, reasoning_effort="low"),
  "stop": dict(base, stop=["\n"]),
  "n": dict(base, n=2),
  "logprobs": dict(base, logprobs=True),
  "OK max_output_tokens": dict(base, max_output_tokens=50),
  "OK text.format json_object": dict(base, text={"format": {"type": "json_object"}}),
  "OK text.verbosity": dict(base, text={"verbosity": "low"}),
  "OK reasoning.effort": dict(base, reasoning={"effort": "low"}),
  "OK top_logprobs": dict(base, top_logprobs=2, include=["message.output_text.logprobs"]),
  "OK input as messages list": dict(model="gpt-5.5", input=[{"role": "user", "content": "hi"}]),
}
for k, kw in cases.items():
    try:
        c.responses.create(**kw); print(f"{k}: sent {json.dumps({x: v for x, v in seen[-1].items() if x not in ('model',)})[:110]}")
    except Exception as e:
        print(f"{k}: {type(e).__name__}: {e}")
