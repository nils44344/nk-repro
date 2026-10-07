import dotenv from 'dotenv'; dotenv.config({ path: '../.env', quiet: true });
import { GoogleGenAI } from '@google/genai';
const ai = new GoogleGenAI({ apiKey: process.env.GEMINI_API_KEY });
const models = process.argv.slice(2);
for (const model of models) {
  try {
    const r = await ai.models.generateContent({ model, contents: 'hi', config: { maxOutputTokens: 1, thinkingConfig: { thinkingBudget: 0 } } });
    console.log(`OK   ${model}`);
  } catch (e) {
    console.log(`ERR  ${model} | ${e.constructor.name} status=${e.status} | ${String(e.message).slice(0, 240).replace(/\s+/g, ' ')}`);
  }
}
