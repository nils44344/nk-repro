import dotenv from 'dotenv'; dotenv.config({ path: '../.env', quiet: true });
import { GoogleGenAI, ApiError } from '@google/genai';
const ai = new GoogleGenAI({ apiKey: process.env.GEMINI_API_KEY });

async function generateWithRetry(params, maxWaits = 4) {
  for (let attempt = 0; ; attempt++) {
    try {
      return await ai.models.generateContent(params);
    } catch (err) {
      if (!(err instanceof ApiError) || attempt >= maxWaits) throw err;
      if (err.status === 503) { const ms = 2000 * 2 ** attempt; console.log(`  503 high demand, waiting ${ms / 1000}s`); await new Promise((r) => setTimeout(r, ms)); continue; }
      if (err.status !== 429) throw err;
      const body = JSON.parse(err.message).error;
      if (/limit: 0\b/.test(body.message)) throw err; // no free quota for this model: waiting won't help
      const delay = body.details?.find((d) => d['@type']?.endsWith('RetryInfo'))?.retryDelay ?? '10s';
      const ms = Math.ceil(parseFloat(delay) * 1000) + 500;
      if (ms > 120_000) throw err; // a daily quota: the delay runs to midnight UTC
      console.log(`  429, waiting ${delay} as Google asked`);
      await new Promise((r) => setTimeout(r, ms));
    }
  }
}

const model = process.argv[2] || 'gemini-3.5-flash';
const t0 = Date.now();
for (let i = 1; i <= Number(process.argv[3] || 10); i++) {
  try { await generateWithRetry({ model, contents: 'hi', config: { maxOutputTokens: 1 } }); console.log(`#${i} OK +${((Date.now() - t0) / 1000).toFixed(0)}s`); }
  catch (e) { console.log(`#${i} gave up: ${e.status} ${String(e.message).match(/limit: \d+/)?.[0] ?? ''}`); break; }
}
