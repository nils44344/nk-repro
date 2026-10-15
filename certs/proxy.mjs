// A stand-in for a corporate TLS-inspecting proxy: an HTTPS server on localhost:8443 whose certificate is signed by
// a private root CA (sent along in the chain), forwarding every request to registry.npmjs.org.
import https from 'node:https';
import { readFileSync } from 'node:fs';

const server = https.createServer(
  { key: readFileSync('leaf.key'), cert: readFileSync('chain.pem') },
  (req, res) => {
    const up = https.request(
      { host: 'registry.npmjs.org', path: req.url, method: req.method, headers: { ...req.headers, host: 'registry.npmjs.org' } },
      (r) => {
        // Rewrite tarball URLs so npm keeps going through this proxy.
        const type = r.headers['content-type'] || '';
        if (type.includes('json')) {
          let body = '';
          r.setEncoding('utf8');
          r.on('data', (c) => (body += c));
          r.on('end', () => {
            const out = body.replaceAll('https://registry.npmjs.org/', 'https://localhost:8443/');
            const h = { ...r.headers }; delete h['content-length']; delete h['content-encoding'];
            res.writeHead(r.statusCode, h); res.end(out);
          });
        } else { res.writeHead(r.statusCode, r.headers); r.pipe(res); }
      },
    );
    up.on('error', (e) => { res.writeHead(502); res.end(String(e)); });
    req.pipe(up);
  },
);
server.listen(8443, () => console.log('proxy on https://localhost:8443'));
