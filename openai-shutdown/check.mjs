// The post-shutdown check from the post, verbatim: a real call tells a live model from a shut-down one.
import dotenv from 'dotenv'; dotenv.config({ path: '../.env', quiet: true });
import OpenAI from 'openai';
const client = new OpenAI({ maxRetries: 0 });

for (const model of ['gpt-3.5-turbo', 'o3-mini', 'gpt-5.6-terra']) {
  try {
    await client.chat.completions.create({ model, messages: [{ role: 'user', content: 'OK' }], max_completion_tokens: 16 });
    console.log(`works  ${model}`);
  } catch (e) {
    console.log(e.status === 404 ? `GONE   ${model}` : `exists ${model} (${e.status})`);
  }
}
