// Shared helpers for the nightly re-checks. Each check reproduces one claim a post makes and says whether it
// still holds on today's versions. A flipped check is news: either the bug was fixed or something new broke.
import { execSync, spawnSync } from 'node:child_process';
import { mkdtempSync, mkdirSync, writeFileSync, readFileSync, existsSync } from 'node:fs';
import { tmpdir } from 'node:os';
import { join, dirname } from 'node:path';

export const isWin = process.platform === 'win32';
export const osName = isWin ? 'Windows' : process.platform === 'darwin' ? 'macOS' : 'Linux';

/** Run a shell command, return stdout+stderr as one string. Never throws: a failing command is often the point. */
export function sh(cmd, cwd, env = {}) {
  const r = spawnSync(cmd, { cwd, shell: true, encoding: 'utf8', env: { ...process.env, ...env }, timeout: 300_000 });
  return `${r.stdout ?? ''}${r.stderr ?? ''}`;
}

export function tmp(name) {
  return mkdtempSync(join(tmpdir(), `nk-${name}-`));
}

/** Write a tree of files: { 'a/b.json': {...} | 'text' } */
export function files(root, tree) {
  for (const [p, body] of Object.entries(tree)) {
    const f = join(root, p);
    mkdirSync(dirname(f), { recursive: true });
    writeFileSync(f, typeof body === 'string' ? body : JSON.stringify(body, null, 2));
  }
}

export function version(cmd) {
  try { return execSync(cmd, { encoding: 'utf8' }).trim().split('\n')[0]; } catch { return 'unknown'; }
}

/** A check: `name` is what the post claims, `run` returns the evidence string, `holds` decides from it. */
export function check(name, run, holds) {
  let out = '';
  try { out = run(); } catch (e) { out = String(e); }
  const ok = !!holds(out);
  return { name, ok, evidence: out.replace(/\s+/g, ' ').trim().slice(0, 300) };
}

/** One file per post per OS (status/<post>--<os>.json), so the Windows and Linux runners never write the same file.
 * build-status.mjs merges them into status/status.json, which the blog reads. */
export function record(post, versions, checks) {
  const file = join(import.meta.dirname, '..', 'status', `${post}--${osName}.json`);
  const run = { post, os: osName, date: new Date().toISOString().slice(0, 10), versions, checks, allHold: checks.every((c) => c.ok) };
  mkdirSync(dirname(file), { recursive: true });
  writeFileSync(file, JSON.stringify(run, null, 2) + '\n');
  for (const c of checks) console.log(`${c.ok ? 'HOLDS  ' : 'CHANGED'} ${post} [${osName}] ${c.name}\n         ${c.evidence.slice(0, 160)}`);
  return checks.every((c) => c.ok);
}
