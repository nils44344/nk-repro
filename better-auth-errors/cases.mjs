// Better Auth: which setup gives which error? Each case runs in its own process (env is read at init).
// Usage: node cases.mjs <case>   |   node cases.mjs all   (runs every case in a child process)
import { spawnSync } from 'node:child_process';
import { readFileSync } from 'node:fs';

const CASES = {
  // --- origin checks (POST with an Origin header, the way a browser sends it) ---
  'origin-same': { opts: { baseURL: 'http://localhost:3000' }, req: ['POST', '/api/auth/sign-up/email', 'http://localhost:3000'] },
  'origin-other-port': { opts: { baseURL: 'http://localhost:3000' }, req: ['POST', '/api/auth/sign-up/email', 'http://localhost:5173'] },
  'origin-other-port-trusted': { opts: { baseURL: 'http://localhost:3000', trustedOrigins: ['http://localhost:5173'] }, req: ['POST', '/api/auth/sign-up/email', 'http://localhost:5173'] },
  'origin-trailing-slash': { opts: { baseURL: 'http://localhost:3000', trustedOrigins: ['http://localhost:5173/'] }, req: ['POST', '/api/auth/sign-up/email', 'http://localhost:5173'] },
  'origin-127-vs-localhost': { opts: { baseURL: 'http://localhost:3000' }, req: ['POST', '/api/auth/sign-up/email', 'http://127.0.0.1:3000'] },
  'origin-https-prod': { opts: { baseURL: 'http://localhost:3000' }, req: ['POST', '/api/auth/sign-up/email', 'https://app.example.com'] },
  'origin-https-prod-trusted': { opts: { baseURL: 'https://app.example.com' }, req: ['POST', '/api/auth/sign-up/email', 'https://app.example.com', 'https://app.example.com'] },
  'origin-wildcard': { opts: { baseURL: 'http://localhost:3000', trustedOrigins: ['https://*.example.com'] }, req: ['POST', '/api/auth/sign-up/email', 'https://preview-42.example.com'] },
  'origin-none-no-cookie': { opts: { baseURL: 'http://localhost:3000' }, req: ['POST', '/api/auth/sign-up/email', null] },
  'signout-other-port': { opts: { baseURL: 'http://localhost:3000' }, req: ['POST', '/api/auth/sign-out', 'http://localhost:5173'], cookie: true },
  'callbackurl-untrusted': { opts: { baseURL: 'http://localhost:3000' }, req: ['POST', '/api/auth/sign-up/email', 'http://localhost:3000'], body: { callbackURL: 'https://evil.example.net/after' } },
  'callbackurl-trusted': { opts: { baseURL: 'http://localhost:3000', trustedOrigins: ['https://app.example.com'] }, req: ['POST', '/api/auth/sign-up/email', 'http://localhost:3000'], body: { callbackURL: 'https://app.example.com/after' } },
  // --- secret ---
  'secret-missing-dev': { env: { NODE_ENV: 'development' }, noSecret: true, opts: { baseURL: 'http://localhost:3000' }, req: ['POST', '/api/auth/sign-up/email', 'http://localhost:3000'] },
  'secret-missing-prod': { env: { NODE_ENV: 'production' }, noSecret: true, opts: { baseURL: 'http://localhost:3000' }, req: ['POST', '/api/auth/sign-up/email', 'http://localhost:3000'] },
  'secret-short': { secret: 'short-secret-123', opts: { baseURL: 'http://localhost:3000' }, req: ['POST', '/api/auth/sign-up/email', 'http://localhost:3000'] },
  'secret-auth-secret-env': { env: { AUTH_SECRET: 'DUMMY-not-a-real-secret-Q7vLm2Rk9TzP4wYc6Nb' }, noSecret: true, opts: { baseURL: 'http://localhost:3000' }, req: ['POST', '/api/auth/sign-up/email', 'http://localhost:3000'] },
  'secret-better-auth-env-prod': { env: { NODE_ENV: 'production', BETTER_AUTH_SECRET: 'DUMMY-not-a-real-secret-Zp4Lq8Wv2Nx6Tb9Rc3Y' }, noSecret: true, opts: { baseURL: 'http://localhost:3000' }, req: ['POST', '/api/auth/sign-up/email', 'http://localhost:3000'] },
  'secret-auth-secret-env-prod': { env: { NODE_ENV: 'production', AUTH_SECRET: 'DUMMY-not-a-real-secret-Zp4Lq8Wv2Nx6Tb9Rc3Y' }, noSecret: true, opts: { baseURL: 'http://localhost:3000' }, req: ['POST', '/api/auth/sign-up/email', 'http://localhost:3000'] },
  'signout-no-origin-cookie': { opts: { baseURL: 'http://localhost:3000' }, req: ['POST', '/api/auth/sign-out', null], cookie: true },
  // --- base URL ---
  'baseurl-missing-prod': { env: { NODE_ENV: 'production' }, opts: {}, req: ['POST', '/api/auth/sign-up/email', 'http://localhost:3000'] },
  'baseurl-missing': { opts: {}, req: ['POST', '/api/auth/sign-up/email', 'http://localhost:3000'] },
  'baseurl-env': { env: { BETTER_AUTH_URL: 'http://localhost:3000' }, opts: {}, req: ['POST', '/api/auth/sign-up/email', 'http://localhost:3000'] },
  'baseurl-no-protocol': { opts: { baseURL: 'localhost:3000' }, req: ['POST', '/api/auth/sign-up/email', 'http://localhost:3000'] },
  'baseurl-path-mismatch': { opts: { baseURL: 'http://localhost:3000' }, req: ['POST', '/auth/sign-up/email', 'http://localhost:3000'] },
};

const SECRET = 'DUMMY-not-a-real-secret-Kq8vT2mLp9Xz4Rb7Nc3W'; // a made-up 40-char test value, not used anywhere real

async function one(name) {
  const c = CASES[name];
  for (const [k, v] of Object.entries(c.env || {})) process.env[k] = v;
  const warns = [];
  const { betterAuth } = await import('better-auth');
  const { memoryAdapter } = await import('better-auth/adapters/memory');
  const db = { user: [], session: [], account: [], verification: [] };
  let auth;
  try {
    auth = betterAuth({
      database: memoryAdapter(db),
      emailAndPassword: { enabled: true },
      ...(c.noSecret ? {} : { secret: c.secret || SECRET }),
      logger: { log: (level, msg) => { if (level !== 'debug') warns.push(`${level}: ${String(msg).split('\n')[0]}`); } },
      ...c.opts,
    });
  } catch (e) { return out(name, warns, `INIT THROW ${e.name}: ${e.message.split('\n')[0]}`); }
  const [method, path, origin, host] = c.req;
  const u = new URL(path, host || 'http://localhost:3000');
  const mk = (cookie) => {
    const h = { 'content-type': 'application/json' };
    if (origin) h.origin = origin;
    if (cookie) h.cookie = cookie;
    return new Request(u, { method, headers: h, body: method === 'POST' ? JSON.stringify({ email: `u${Date.now()}@example.com`, password: 'test-password-123', name: 'Test', ...(c.body || {}) }) : undefined });
  };
  let cookie;
  if (c.cookie) {
    // sign up first from the same origin to get a session cookie
    const r0 = await auth.handler(new Request(new URL('/api/auth/sign-up/email', u), { method: 'POST', headers: { 'content-type': 'application/json', origin: 'http://localhost:3000' }, body: JSON.stringify({ email: 'c@example.com', password: 'test-password-123', name: 'C' }) }));
    cookie = (r0.headers.get('set-cookie') || '').split(';')[0];
  }
  let res;
  try { res = await auth.handler(mk(cookie)); }
  catch (e) { return out(name, warns, `HANDLER THROW ${e.name}: ${e.message.split('\n')[0]}`); }
  const text = await res.text();
  return out(name, warns, `HTTP ${res.status} ${text.slice(0, 200)}`);
}

function out(name, warns, result) {
  console.log(`## ${name}`);
  for (const w of [...new Set(warns)]) console.log(`  log  ${w}`);
  console.log(`  ->   ${result}`);
}

const arg = process.argv[2];
if (arg === 'all') {
  const v = JSON.parse(readFileSync(new URL('./node_modules/better-auth/package.json', import.meta.url))).version;
  console.log(`better-auth ${v} | node ${process.version} | ${process.platform} | ${new Date().toISOString()}`);
  for (const name of Object.keys(CASES)) {
    const r = spawnSync(process.execPath, [new URL(import.meta.url).pathname.replace(/^\/([A-Z]:)/, '$1'), name], { encoding: 'utf8', env: { PATH: process.env.PATH, SYSTEMROOT: process.env.SYSTEMROOT || '' } });
    process.stdout.write(r.stdout);
    const err = (r.stderr || '').split('\n').filter((l) => l.trim() && !/ExperimentalWarning|--trace/.test(l)).slice(0, 4);
    for (const l of err) console.log(`  err  ${l.slice(0, 220)}`);
  }
} else await one(arg);
