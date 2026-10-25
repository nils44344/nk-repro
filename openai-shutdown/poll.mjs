// Polls the Oct 23 shutdown models every 15 min (free: a $0 key gets 429 while a model exists, 404 once it is gone).
// Writes every status change with a UTC timestamp to poll.log.
import dotenv from 'dotenv'; dotenv.config({ path: '../.env', quiet: true });
import OpenAI from 'openai';
import fs from 'node:fs';
const client = new OpenAI({ maxRetries: 0 });
const models = ['gpt-3.5-turbo', 'gpt-3.5-turbo-0125', 'gpt-4.1-nano', 'gpt-4o-2024-05-13', 'o1', 'o1-pro', 'o3-mini', 'o4-mini', 'gpt-4o', 'gpt-4o-mini'];
const last = {};
const log = (s) => fs.appendFileSync('poll.log', `${new Date().toISOString()} ${s}\n`);
async function check() {
  for (const model of models) {
    let st;
    try { await client.chat.completions.create({ model, messages: [{ role: 'user', content: 'OK' }], max_completion_tokens: 16 }); st = 'OK'; }
    catch (e) { st = `${e.status} ${e.code} | ${String(e.message).slice(0, 160)}`; }
    if (last[model] !== st) { log(`${model}: ${st}`); last[model] = st; }
  }
}
const end = Date.now() + 40 * 3600e3;
while (Date.now() < end) { try { await check(); } catch (e) { log(`poll error: ${e.message}`); } await new Promise((r) => setTimeout(r, 15 * 60e3)); }
