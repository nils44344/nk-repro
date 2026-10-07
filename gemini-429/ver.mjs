import dotenv from 'dotenv'; dotenv.config({ path: '../.env', quiet: true });
import { GoogleGenAI } from '@google/genai';
const ai = new GoogleGenAI({ apiKey: process.env.GEMINI_API_KEY });
for (const model of process.argv.slice(2)) {
  try { const r = await ai.models.generateContent({ model, contents: 'hi', config: { maxOutputTokens: 1 } }); console.log(`${model} -> OK, modelVersion=${r.modelVersion}`); }
  catch (e) { console.log(`${model} -> ${e.status} ${String(e.message).match(/limit: \d+, model: [\w.-]+|high demand|no longer available[^.]*/)?.[0] ?? ''}`); }
}
