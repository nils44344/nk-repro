// "models/X is not found for API version v1beta, or is not supported for generateContent" (8 Nov 2026).
// 1) Which model names each API version lists for generateContent. 2) Common names tried on v1 and v1beta over
// plain REST (the same URL every SDK calls). maxOutputTokens 1 to spend almost no quota. Never prints the key.
const KEY = process.env.GEMINI_API_KEY;
if (!KEY) throw new Error('set GEMINI_API_KEY');
const H = { 'x-goog-api-key': KEY, 'content-type': 'application/json' };
const base = (v) => `https://generativelanguage.googleapis.com/${v}`;

const list = async (v) => {
  const names = [];
  let page = '';
  do {
    const r = await fetch(`${base(v)}/models?pageSize=1000${page ? `&pageToken=${page}` : ''}`, { headers: H });
    const j = await r.json();
    for (const m of j.models || []) if ((m.supportedGenerationMethods || []).includes('generateContent')) names.push(m.name.replace('models/', ''));
    page = j.nextPageToken || '';
  } while (page);
  return names.filter((n) => n.startsWith('gemini')).sort();
};

const v1 = await list('v1');
const v1beta = await list('v1beta');
console.log(`# generateContent models listed: v1 ${v1.length}, v1beta ${v1beta.length}`);
console.log(`## v1:\n${v1.join('\n')}`);
console.log(`## only on v1beta:\n${v1beta.filter((n) => !v1.includes(n)).join('\n')}`);
console.log(`## only on v1:\n${v1.filter((n) => !v1beta.includes(n)).join('\n') || '(none)'}`);

const tries = [
  'gemini-1.5-flash', 'gemini-1.5-flash-latest', 'gemini-pro', 'gemini-2.0-flash', 'gemini-2.5-flash',
  'gemini-2.5-flash-latest', 'gemini-3-flash', 'gemini-3.1-flash', 'gemini-flash-latest', 'gemini-3.1-pro-preview',
  'models/gemini-2.5-flash', 'Gemini-2.5-Flash', 'gemini-2.5-flash ',
];
console.log('\n# generateContent: name | v1 | v1beta');
for (const name of tries) {
  const row = [];
  for (const v of ['v1', 'v1beta']) {
    const id = name.startsWith('models/') ? name : `models/${name}`;
    const r = await fetch(`${base(v)}/${encodeURI(id)}:generateContent`, {
      method: 'POST', headers: H,
      body: JSON.stringify({ contents: [{ parts: [{ text: 'Reply with one word: hi' }] }], generationConfig: { maxOutputTokens: 1 } }),
    });
    const j = await r.json().catch(() => ({}));
    row.push(r.ok ? `200 ${j.modelVersion}` : `${r.status} ${(j.error?.message || '').slice(0, 150)}`);
  }
  console.log(`${JSON.stringify(name)} | ${row.join(' | ')}`);
}
