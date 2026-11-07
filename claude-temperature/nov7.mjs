// Does the 2026-10-21 API version reject `temperature` on every model? @anthropic-ai/sdk default, one-token Haiku calls (7 Nov 2026).
// Key from ANTH_KEY env; never printed. Run with ANTHROPIC_BASE_URL unset.
import Anthropic from '@anthropic-ai/sdk';
import { readFileSync } from 'node:fs';
let version;
const client = new Anthropic({ apiKey: process.env.ANTH_KEY, fetch: (u, o) => { version = new Headers(o.headers).get('anthropic-version'); return fetch(u, o); } });
console.log('sdk', JSON.parse(readFileSync('node_modules/@anthropic-ai/sdk/package.json')).version);
for (const model of ['claude-haiku-4-5-20251001', 'claude-haiku-5-5']) {
  for (const [label, extra] of [['no sampling params', {}], ['temperature: 0', { temperature: 0 }], ['temperature: 1', { temperature: 1 }]]) {
    try {
      const r = await client.messages.create({ model, max_tokens: 1, messages: [{ role: 'user', content: 'hi' }], ...extra });
      console.log(`${model} | ${label} | OK (${r.model}) | anthropic-version ${version}`);
    } catch (e) {
      console.log(`${model} | ${label} | ${e.status ?? e.name} | ${(e.error?.error?.message ?? e.message).slice(0, 160)} | anthropic-version ${version}`);
    }
  }
}
