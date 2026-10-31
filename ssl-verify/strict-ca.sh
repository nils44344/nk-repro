#!/bin/bash
# A local HTTPS server signed by a CA whose basicConstraints is NOT marked critical (common in corporate proxies and
# antivirus roots). Python 3.13+ sets VERIFY_X509_STRICT by default; older versions accept this CA.
set +e
D=$(mktemp -d); cd "$D"
openssl req -x509 -newkey rsa:2048 -nodes -keyout ca.key -out ca.pem -days 2 -subj "/CN=Test Proxy Root" \
  -addext "basicConstraints=CA:TRUE" -addext "keyUsage=critical,keyCertSign,cRLSign" 2>/dev/null
openssl req -newkey rsa:2048 -nodes -keyout srv.key -out srv.csr -subj "/CN=localhost" 2>/dev/null
printf 'subjectAltName=DNS:localhost\nbasicConstraints=CA:FALSE\nkeyUsage=critical,digitalSignature,keyEncipherment\nextendedKeyUsage=serverAuth\nauthorityKeyIdentifier=keyid\nsubjectKeyIdentifier=hash\n' > ext.cnf
openssl x509 -req -in srv.csr -CA ca.pem -CAkey ca.key -CAcreateserial -out srv.pem -days 2 -extfile ext.cnf 2>/dev/null
openssl x509 -in ca.pem -noout -ext basicConstraints
python3 - <<'PY' &
import http.server, ssl
s = http.server.HTTPServer(('localhost', 8443), http.server.SimpleHTTPRequestHandler)
c = ssl.SSLContext(ssl.PROTOCOL_TLS_SERVER); c.load_cert_chain('srv.pem', 'srv.key')
s.socket = c.wrap_socket(s.socket, server_side=True); s.serve_forever()
PY
sleep 2
python "$GITHUB_WORKSPACE/ssl-verify/probe.py" https://localhost:8443/ "$D/ca.pem"
echo "== SSL_CERT_FILE=ca.pem, default urllib"
SSL_CERT_FILE="$D/ca.pem" python -c "import urllib.request; urllib.request.urlopen('https://localhost:8443/', timeout=10); print('OK')" 2>&1 | tail -1
echo "== requests with an HTTPAdapter whose ssl_context has the strict flag cleared"
python - "$D/ca.pem" <<'PY2' 2>&1 | tail -1
import ssl, sys, requests
from requests.adapters import HTTPAdapter
class A(HTTPAdapter):
    def init_poolmanager(self, *a, **k):
        c = ssl.create_default_context(cafile=sys.argv[1]); c.verify_flags &= ~ssl.VERIFY_X509_STRICT
        k['ssl_context'] = c; return super().init_poolmanager(*a, **k)
s = requests.Session(); s.mount('https://', A()); s.get('https://localhost:8443/', timeout=10); print('requests with adapter OK')
PY2
echo "== CA added to the system store (update-ca-certificates), then truststore and plain urllib"
sudo cp "$D/ca.pem" /usr/local/share/ca-certificates/test-proxy-root.crt && sudo update-ca-certificates >/dev/null 2>&1
python -c "import truststore,requests; truststore.inject_into_ssl(); requests.get('https://localhost:8443/', timeout=10); print('truststore + system store OK')" 2>&1 | tail -1 | cut -c1-220
python -c "import urllib.request; urllib.request.urlopen('https://localhost:8443/', timeout=10); print('urllib + system store OK')" 2>&1 | tail -1 | cut -c1-220
kill %1 2>/dev/null
