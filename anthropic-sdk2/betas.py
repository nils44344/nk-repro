import json, threading, anthropic
from http.server import BaseHTTPRequestHandler, HTTPServer
seen=[]
class H(BaseHTTPRequestHandler):
    def do_POST(self):
        body=self.rfile.read(int(self.headers.get("content-length",0))); seen.append((self.path,{k.lower():v for k,v in self.headers.items()},body))
        out=json.dumps({"id":"m","type":"message","role":"assistant","model":"x","content":[],"stop_reason":"end_turn","stop_sequence":None,"usage":{"input_tokens":1,"output_tokens":1}}).encode()
        self.send_response(200);self.send_header("content-type","application/json");self.send_header("content-length",str(len(out)));self.end_headers();self.wfile.write(out)
    def log_message(self,*a):pass
s=HTTPServer(("127.0.0.1",0),H);threading.Thread(target=s.serve_forever,daemon=True).start()
c=anthropic.Anthropic(api_key="sk-ant-fake",base_url=f"http://127.0.0.1:{s.server_port}",max_retries=0)
m=[{"role":"user","content":"hi"}]
print(anthropic.__version__)
for label,fn in [("messages.create(betas=)",lambda: c.messages.create(model="m",max_tokens=5,messages=m,betas=["context-1m-2025-08-07"])),
                 ("beta.messages.create(betas=)",lambda: c.beta.messages.create(model="m",max_tokens=5,messages=m,betas=["context-1m-2025-08-07"])),
                 ("beta.messages.create(temperature=)",lambda: c.beta.messages.create(model="m",max_tokens=5,messages=m,temperature=0.2))]:
    try: fn(); p,h,b=seen[-1]; print(label,"OK",p,h.get("anthropic-beta"), json.loads(b).get("temperature"))
    except Exception as e: print(label,type(e).__name__+":",e)
