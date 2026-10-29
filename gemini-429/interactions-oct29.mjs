// Does the Interactions API work with the same key and replacement models? (29 Oct 2026)
import dotenv from 'dotenv'; dotenv.config({ path: '../.env', quiet: true });
import { GoogleGenAI } from '@google/genai';
const ai = new GoogleGenAI({ apiKey: process.env.GEMINI_API_KEY });
for (const model of ['gemini-2.5-flash', 'gemini-3.6-flash', 'gemini-3.5-flash-lite']) {
  try {
    const r = await ai.interactions.create({ model, input: 'Reply with one word: hi' });
    const out = r.output_text;
    console.log(`${model} | interactions OK | status=${r.status} | text=${JSON.stringify(out).slice(0, 60)} | keys=${Object.keys(r).join(',')}`);
  } catch (e) { console.log(`${model} | interactions ERR ${e.status ?? ''} | ${String(e.message).replace(/AIza[\w-]+/g, '<key>').slice(0, 260)}`); }
}
