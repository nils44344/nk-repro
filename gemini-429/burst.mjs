import dotenv from 'dotenv'; dotenv.config({ path: '../.env', quiet: true });
import { GoogleGenAI } from '@google/genai';
const ai = new GoogleGenAI({ apiKey: process.env.GEMINI_API_KEY });
const model = process.argv[2] || 'gemini-3.5-flash';
const t0 = Date.now();
for (let i = 1; i <= 25; i++) {
  try { await ai.models.generateContent({ model, contents: 'hi', config: { maxOutputTokens: 1 } }); console.log(`#${i} OK  +${((Date.now()-t0)/1000).toFixed(1)}s`); }
  catch (e) {
    let j; try { j = JSON.parse(e.message).error; } catch {}
    console.log(`#${i} ${e.status} +${((Date.now()-t0)/1000).toFixed(1)}s`);
    if (e.status === 429) {
      console.log('message:', j.message.replace(/\n/g, ' | '));
      console.log('quotaIds:', j.details.find(d => d['@type'].endsWith('QuotaFailure'))?.violations.map(v => v.quotaId + (v.quotaValue ? ' value=' + v.quotaValue : '')).join(', '));
      console.log('retryDelay:', j.details.find(d => d['@type'].endsWith('RetryInfo'))?.retryDelay);
      break;
    }
  }
}
