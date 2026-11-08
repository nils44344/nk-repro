#!/bin/bash
# The error says "You can run `openai migrate` to automatically upgrade your codebase". Does it? (8 Nov 2026)
# Latest openai from PyPI, a small pre-1.0 file, run the migrate command, show the diff, then run the result
# against the local fake server from cc.py's approach.
set +e
W=${W:-$(pwd)/work-migrate}; rm -rf "$W"; mkdir -p "$W/app"; cd "$W" || exit 1
python -m venv v && . v/bin/activate
pip install -q --disable-pip-version-check openai
echo "== $(date -u +%F) $(python -V) openai $(python -c 'import openai;print(openai.__version__)')"
cd app && git init -q && git config user.email t@t && git config user.name t
cat > old.py <<'PY'
import openai

openai.api_key = "sk-test"
openai.api_base = "http://127.0.0.1:8765/v1"

def ask(q):
    try:
        response = openai.ChatCompletion.create(
            model="gpt-4.1-mini",
            messages=[{"role": "user", "content": q}],
        )
        return response["choices"][0]["message"]["content"]
    except openai.error.RateLimitError:
        return "rate limited"

def embed(t):
    return openai.Embedding.create(model="text-embedding-3-small", input=t)["data"][0]["embedding"]

if __name__ == "__main__":
    print(ask("hi"))
    print(embed("hi"))
PY
git add -A && git commit -qm old
echo; echo "### the old file on the new SDK"
python old.py 2>&1 | tail -2
echo; echo "### openai migrate --help"
timeout 60 openai migrate --help 2>&1 | head -15
echo; echo "### openai migrate (in the repo)"
timeout 300 openai migrate < /dev/null 2>&1 | tail -25
echo; echo "### diff"
git --no-pager diff --stat; git --no-pager diff | head -60
echo; echo "### run the migrated file against a local fake API"
cat > ../fake.py <<'PY'
import json
from http.server import BaseHTTPRequestHandler, HTTPServer
class H(BaseHTTPRequestHandler):
    def do_POST(self):
        self.rfile.read(int(self.headers.get("content-length") or 0))
        out = json.dumps({"id": "c1", "object": "chat.completion", "created": 0, "model": "gpt-4.1-mini",
            "choices": [{"index": 0, "finish_reason": "stop", "message": {"role": "assistant", "content": "hi from fake"}}],
            "data": [{"object": "embedding", "index": 0, "embedding": [0.1]}], "usage": {"prompt_tokens": 1, "completion_tokens": 1, "total_tokens": 2}}).encode()
        self.send_response(200); self.send_header("content-type", "application/json"); self.send_header("content-length", str(len(out))); self.end_headers(); self.wfile.write(out)
        print("FAKE got", self.path, flush=True)
    def log_message(self, *a): pass
HTTPServer(("127.0.0.1", 8765), H).serve_forever()
PY
(python ../fake.py > ../fake.log 2>&1 &); sleep 2
OPENAI_API_KEY=sk-test timeout 30 python old.py 2>&1 | tail -4
echo "fake server saw:"; cat ../fake.log
echo "== done"
