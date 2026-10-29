// Re-test retired Gemini model names + replacements (29 Oct 2026). Never prints the key.
import dotenv from 'dotenv'; dotenv.config({ path: '../.env', quiet: true });
import { GoogleGenAI } from '@google/genai';
const ai = new GoogleGenAI({ apiKey: process.env.GEMINI_API_KEY });
const names = ['gemini-2.5-flash','gemini-2.5-pro','gemini-2.5-flash-lite','gemini-2.0-flash','gemini-2.0-flash-lite','gemini-1.5-flash','gemini-3.5-flash','gemini-3.6-flash','gemini-3.8-flash','gemini-3.5-flash-lite','gemini-flash-latest','gemini-flash-lite-latest','gemini-3.1-pro-preview'];
for (const model of names) {
  const t = Date.now();
  try {
    const r = await Promise.race([ai.models.generateContent({ model, contents: 'Reply with one word: hi' }), new Promise((_, j) => setTimeout(() => j(new Error('timeout 60s')), 60000))]);
    console.log(`${model} | OK | modelVersion=${r.modelVersion} | ${Date.now() - t} ms`);
  } catch (e) {
    let msg = String(e.message || e).replace(/AIza[\w-]+/g, '<key>');
    const m = msg.match(/"message":\s*"([^"]+)/); console.log(`${model} | ERR ${e.status ?? ''} | ${(m ? m[1] : msg).slice(0, 300)}`);
  }
}
const listed = []; for await (const m of await ai.models.list()) listed.push(m.name.replace('models/', ''));
console.log('listed 2.5-flash:', listed.includes('gemini-2.5-flash'), '| listed 3.8-flash:', listed.includes('gemini-3.8-flash'));
console.log('sdk', JSON.parse((await import('node:fs')).readFileSync('node_modules/@google/genai/package.json')).version);
