import json, threading
from http.server import BaseHTTPRequestHandler, HTTPServer
import anthropic
seen=[]
class H(BaseHTTPRequestHandler):
    def do_POST(self):
        self.rfile.read(int(self.headers.get("content-length",0))); seen.append({k.lower():v for k,v in self.headers.items()})
        out=json.dumps({"id":"m","type":"message","role":"assistant","model":"x","content":[],"stop_reason":"end_turn","stop_sequence":None,"usage":{"input_tokens":1,"output_tokens":1}}).encode()
        self.send_response(200);self.send_header("content-type","application/json");self.send_header("content-length",str(len(out)));self.end_headers();self.wfile.write(out)
    def log_message(self,*a):pass
s=HTTPServer(("127.0.0.1",0),H);threading.Thread(target=s.serve_forever,daemon=True).start();b=f"http://127.0.0.1:{s.server_port}"
def show(label,c,**kw):
    c.messages.create(model="m",max_tokens=5,messages=[{"role":"user","content":"hi"}],**kw);h=seen[-1]
    print(label,{k:h.get(k) for k in("x-api-key","authorization","anthropic-version")})
show("default_headers version", anthropic.Anthropic(api_key="sk-ant-fake",base_url=b,default_headers={"anthropic-version":"2023-06-01"}))
show("extra_headers version", anthropic.Anthropic(api_key="sk-ant-fake",base_url=b), extra_headers={"anthropic-version":"2023-06-01"})
show("auth_token + X-Api-Key header", anthropic.Anthropic(auth_token="gw-token",base_url=b,default_headers={"X-Api-Key":"sk-ant-fake"}))
import os; os.environ.pop("ANTHROPIC_API_KEY",None)
try: show("only X-Api-Key header", anthropic.Anthropic(base_url=b,default_headers={"X-Api-Key":"sk-ant-fake"}))
except Exception as e: print(type(e).__name__, e)
try: show("X-Api-Key + Authorization omitted", anthropic.Anthropic(base_url=b,default_headers={"X-Api-Key":"sk-ant-fake","Authorization":anthropic.Omit()}))
except Exception as e: print(type(e).__name__, e)
