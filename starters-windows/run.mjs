// Scaffold → install → build → dev server for each framework starter, non-interactively, recording what happened.
// Usage: node run.mjs [id ...]   (no ids = all). Results: results-<os>.json next to this file.
import { spawn, spawnSync } from 'node:child_process';
import { existsSync, readFileSync, writeFileSync, rmSync, mkdirSync, readdirSync, statSync } from 'node:fs';
import { join } from 'node:path';

const isWin = process.platform === 'win32';
const OS = isWin ? 'Windows' : 'Linux';
const ROOT = join(import.meta.dirname, 'work-' + OS.toLowerCase());
const OUT = join(import.meta.dirname, `results-${OS.toLowerCase()}.json`);
mkdirSync(ROOT, { recursive: true });

// Keep npm's cache and temp files off a nearly full C: drive (Windows); harmless on Linux.
const ENV = { ...process.env, CI: '1', npm_config_yes: 'true', npm_config_fund: 'false', npm_config_audit: 'false', NO_COLOR: '1', FORCE_COLOR: '0', NEXT_TELEMETRY_DISABLED: '1', ASTRO_TELEMETRY_DISABLED: '1', NUXT_TELEMETRY_DISABLED: '1', NG_CLI_ANALYTICS: 'false', DO_NOT_TRACK: '1' };
if (isWin) Object.assign(ENV, { npm_config_cache: 'D:\\nk-repro\\npm-cache', TEMP: 'D:\\nk-repro\\tmp', TMP: 'D:\\nk-repro\\tmp' });
if (isWin) mkdirSync('D:\\nk-repro\\tmp', { recursive: true });

// id, scaffold command (creates ./app), the package whose version we report, and the dev command.
const STARTERS = [
  { id: 'next', name: 'Next.js', cmd: 'npx --yes create-next-app@latest app --yes --use-npm --disable-git', pkg: 'next', dev: 'npm run dev' },
  { id: 'vite-react', name: 'Vite + React', cmd: 'npm create vite@latest app -- --template react-ts --no-interactive', pkg: 'vite', dev: 'npm run dev' },
  { id: 'vue', name: 'Vue (create-vue)', cmd: 'npm create vue@latest app -- --default', pkg: 'vue', dev: 'npm run dev' },
  { id: 'astro', name: 'Astro', cmd: 'npm create astro@latest app -- --template minimal --install --no-git --yes', pkg: 'astro', dev: 'npm run dev' },
  { id: 'sveltekit', name: 'SvelteKit', cmd: 'npx --yes sv@latest create app --template minimal --types ts --no-add-ons --install npm', pkg: '@sveltejs/kit', dev: 'npm run dev' },
  { id: 'nuxt', name: 'Nuxt', cmd: 'npx --yes nuxi@latest init app --template minimal --packageManager npm --gitInit false --no-modules', pkg: 'nuxt', dev: 'npm run dev' },
  { id: 'angular', name: 'Angular', cmd: 'npx --yes @angular/cli@latest new app --defaults --skip-git --ssr false', pkg: '@angular/core', dev: 'npx ng serve' },
  { id: 'react-router', name: 'React Router', cmd: 'npx --yes create-react-router@latest app --yes --no-git-init', pkg: 'react-router', dev: 'npm run dev' },
  { id: 'nest', name: 'NestJS', cmd: 'npx --yes @nestjs/cli@latest new app --package-manager npm --skip-git', pkg: '@nestjs/core', dev: 'npm run start', port: 3000 },
  { id: 'expo', name: 'Expo', cmd: 'npx --yes create-expo-app@latest app --yes', pkg: 'expo', dev: 'npx expo start --web --port 8081' },
  { id: 'cloudflare', name: 'Cloudflare (C3)', cmd: 'npm create cloudflare@latest app -- --type hello-world --lang ts --no-deploy --no-git --no-open --no-agents', pkg: 'wrangler', dev: 'npx wrangler dev' },
  { id: 'hono', name: 'Hono', cmd: 'npm create hono@latest app -- --template nodejs --install --pm npm', pkg: 'hono', dev: 'npm run dev' },
  { id: 'qwik', name: 'Qwik', cmd: 'npm create qwik@latest empty app -- --installDeps', pkg: '@builder.io/qwik', dev: 'npm run dev' },
  { id: 'docusaurus', name: 'Docusaurus', cmd: 'npx --yes create-docusaurus@latest app classic --typescript --package-manager npm', pkg: '@docusaurus/core', dev: 'npm run start -- --no-open' },
  { id: 'electron', name: 'Electron Forge', cmd: 'npx --yes create-electron-app@latest app --template vite --typescript', pkg: 'electron', dev: null },
  { id: 't3', name: 'create-t3-app', cmd: 'npx --yes create-t3-app@latest app --CI --tailwind --trpc --appRouter --noGit', pkg: 'next', dev: 'npm run dev' },
];

const strip = (s) => String(s).replace(/\x1b\[[0-9;?]*[A-Za-z]/g, '');
const firstError = (out) => strip(out).split(/\r?\n/).map((l) => l.trim()).find((l) => /\b(error|ERR!|ERR_|failed|Cannot|ENOENT|EPERM|EACCES|EBUSY)\b/i.test(l) && !/0 errors?|no errors|warn/i.test(l)) ?? '';

/** Run to completion with a timeout; stdin closed so a prompt fails fast instead of hanging. */
function run(cmd, cwd, timeoutMs) {
  const t = Date.now();
  const r = spawnSync(cmd, { cwd, shell: true, env: ENV, encoding: 'utf8', timeout: timeoutMs, stdio: ['ignore', 'pipe', 'pipe'], maxBuffer: 64 * 1024 * 1024 });
  const out = `${r.stdout ?? ''}${r.stderr ?? ''}`;
  return { code: r.status, timedOut: r.error?.code === 'ETIMEDOUT', secs: Math.round((Date.now() - t) / 100) / 10, out, err: r.status === 0 ? '' : firstError(out) || strip(out).trim().split(/\r?\n/).slice(-3).join(' | ') };
}

function killTree(child) {
  try { if (isWin) spawnSync(`taskkill /PID ${child.pid} /T /F`, { shell: true }); else process.kill(-child.pid, 'SIGKILL'); } catch {}
}

/** Start the dev server, wait for a localhost URL in its output, request it, then stop the whole process tree. */
function dev(cmd, cwd, timeoutMs = 150_000, port) {
  return new Promise((resolve) => {
    const t = Date.now();
    const child = spawn(cmd, { cwd, shell: true, env: ENV, detached: !isWin, stdio: ['ignore', 'pipe', 'pipe'] });
    let out = '', done = false, fetching = false;
    const finish = (res) => { if (done) return; done = true; clearTimeout(timer); killTree(child); resolve({ ...res, secs: Math.round((Date.now() - t) / 100) / 10, tail: strip(out).trim().split(/\r?\n/).slice(-4).join(' | ').slice(0, 400) }); };
    const onData = async (d) => {
      out += d;
      const m = strip(out).match(/https?:\/\/(?:localhost|127\.0\.0\.1|\[::1\]|0\.0\.0\.0):(\d{2,5})/);
      if (m && !fetching) {
        fetching = true;
        // A server may listen on IPv4 or IPv6 only, and `localhost` can resolve to the other one (it does in Docker): try all three.
        const urls = [`http://127.0.0.1:${m[1]}/`, `http://[::1]:${m[1]}/`, `http://localhost:${m[1]}/`];
        const url = urls[2];
        for (let i = 0; i < 40 && !done; i++) {
          for (const u of urls) {
            try { const r = await fetch(u, { signal: AbortSignal.timeout(20_000) }); if (r.status === 503) continue; return finish({ ok: r.status < 500, status: r.status, url: u }); } catch {} // 503 = still starting (Nuxt): keep waiting
          }
          await new Promise((z) => setTimeout(z, 3000));
        }
        finish({ ok: false, status: 0, url, err: 'server printed a URL but never answered' });
      }
    };
    child.stdout.on('data', onData); child.stderr.on('data', onData);
    // Some servers print no URL (NestJS just listens on 3000): poll the known port.
    if (port) { const poll = setInterval(() => { if (done) return clearInterval(poll); if (!fetching) { out += `
http://localhost:${port}/
`; onData(''); clearInterval(poll); } }, 15_000); }
    child.on('exit', (code) => finish({ ok: false, status: 0, err: `dev process exited (${code}) before serving: ${firstError(out)}` }));
    const timer = setTimeout(() => finish({ ok: false, status: 0, err: 'no URL within ' + timeoutMs / 1000 + ' s' }), timeoutMs);
  });
}

function dirSizeMB(p) {
  let n = 0, files = 0;
  const walk = (d) => { for (const e of readdirSync(d, { withFileTypes: true })) { const f = join(d, e.name); if (e.isDirectory()) walk(f); else if (e.isFile()) { n += statSync(f).size; files++; } } };
  try { walk(p); } catch {}
  return { mb: Math.round(n / 1e5) / 10, files };
}

const want = process.argv.slice(2);
const results = existsSync(OUT) ? JSON.parse(readFileSync(OUT, 'utf8')) : {};
for (const s of STARTERS.filter((s) => !want.length || want.includes(s.id))) {
  const dir = join(ROOT, s.id);
  rmSync(dir, { recursive: true, force: true });
  mkdirSync(dir, { recursive: true });
  const app = join(dir, 'app');
  const r = { name: s.name, os: OS, date: new Date().toISOString().slice(0, 10), node: process.version };
  console.log(`\n=== ${s.name}`);
  const sc = run(s.cmd, dir, 12 * 60_000);
  r.scaffold = { ok: sc.code === 0 && existsSync(join(app, 'package.json')), secs: sc.secs, err: sc.err, timedOut: sc.timedOut };
  writeFileSync(join(dir, 'scaffold.log'), strip(sc.out));
  if (existsSync(join(app, 'package.json'))) {
    const pj = JSON.parse(readFileSync(join(app, 'package.json'), 'utf8'));
    if (!existsSync(join(app, 'node_modules'))) {
      const ins = run('npm install', app, 12 * 60_000);
      r.install = { ok: ins.code === 0, secs: ins.secs, err: ins.err, ran: true };
      writeFileSync(join(dir, 'install.log'), strip(ins.out));
    } else r.install = { ok: true, ran: false };
    try { r.version = JSON.parse(readFileSync(join(app, 'node_modules', ...s.pkg.split('/'), 'package.json'), 'utf8')).version; } catch { r.version = '?'; }
    const deprecated = (strip((existsSync(join(dir, 'install.log')) ? readFileSync(join(dir, 'install.log'), 'utf8') : '') + sc.out).match(/npm warn deprecated/gi) || []).length;
    r.deprecatedWarnings = deprecated;
    r.size = dirSizeMB(join(app, 'node_modules'));
    if (pj.scripts?.build) {
      const b = run('npm run build', app, 12 * 60_000);
      r.build = { ok: b.code === 0, secs: b.secs, err: b.err };
      writeFileSync(join(dir, 'build.log'), strip(b.out));
    }
    if (s.dev) r.dev = await dev(s.dev, app, 150_000, s.port);
  }
  console.log(JSON.stringify(r));
  results[s.id] = r;
  writeFileSync(OUT, JSON.stringify(results, null, 2));
}
