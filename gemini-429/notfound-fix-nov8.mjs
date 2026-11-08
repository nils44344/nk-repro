// The fixes for "is not found for API version": names that ListModels returns, on the version that lists them,
// and which API version each @google/genai major calls by default (8 Nov 2026). Never prints the key.
const KEY = process.env.GEMINI_API_KEY;
const H = { 'x-goog-api-key': KEY, 'content-type': 'application/json' };
const call = async (v, name) => {
  for (let i = 0; i < 3; i++) {
    let r;
    try { r = await fetch(`https://generativelanguage.googleapis.com/${v}/models/${name}:generateContent`, {
      method: 'POST', headers: H, signal: AbortSignal.timeout(45000),
      body: JSON.stringify({ contents: [{ parts: [{ text: 'Reply with one word: hi' }] }], generationConfig: { maxOutputTokens: 1 } }),
    }); } catch (e) { if (i < 2) continue; return `no answer in 45 s (${e.name})`; }
    const j = await r.json().catch(() => ({}));
    if (r.status === 503 && i < 2) { await new Promise((s) => setTimeout(s, 5000)); continue; }
    return r.ok ? `200 ${j.modelVersion}` : `${r.status} ${(j.error?.message || '').slice(0, 110)}`;
  }
};
console.log('# REST: name | v1 | v1beta');
for (const n of ['gemini-3.8-flash', 'gemini-3.5-flash', 'gemini-2.5-flash-lite', 'gemini-3-flash-preview', 'gemini-flash-latest'])
  console.log(`${n} | ${await call('v1', n)} | ${await call('v1beta', n)}`);

console.log('\n# Which URL each SDK major calls by default (fetch intercepted, request not sent)');
const realFetch = globalThis.fetch;
for (const [label, pkg] of [['@google/genai 2.x', '@google/genai'], ['@google/genai 3.0', 'genai3']]) {
  const { GoogleGenAI } = await import(pkg);
  let url = '';
  globalThis.fetch = async (u) => { url = String(u); throw new Error('stop'); };
  try { await new GoogleGenAI({ apiKey: 'x' }).models.generateContent({ model: 'gemini-3.8-flash', contents: 'hi' }); } catch {}
  globalThis.fetch = realFetch;
  const ver = JSON.parse((await import('node:fs')).readFileSync(`node_modules/${pkg}/package.json`, 'utf8')).version;
  console.log(`${label} (${ver}) -> ${url.replace(/\?.*/, '')}`);
}
