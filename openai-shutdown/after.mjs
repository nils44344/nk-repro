// After the Oct 23, 2026 shutdown: does models.retrieve still return the removed models, and what does a call get?
import dotenv from 'dotenv'; dotenv.config({ path: '../.env', quiet: true });
import OpenAI from 'openai';
const client = new OpenAI({ maxRetries: 0 });
for (const id of ['gpt-3.5-turbo', 'o3-mini', 'o4-mini', 'o1', 'gpt-4.1-nano', 'o1-pro', 'gpt-4', 'gpt-4-turbo', 'gpt-5.6-terra']) {
  const r = await client.models.retrieve(id).then((m) => `retrieve OK (${m.id})`, (e) => `retrieve ${e.status}`);
  const c = await client.chat.completions.create({ model: id, messages: [{ role: 'user', content: 'OK' }], max_completion_tokens: 16 })
    .then(() => 'call OK', (e) => `call ${e.status} ${String(e.message).slice(0, 70)}`);
  console.log(id.padEnd(15), r.padEnd(32), c);
}
