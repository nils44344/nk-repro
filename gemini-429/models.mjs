import dotenv from 'dotenv'; dotenv.config({ path: '../.env', quiet: true });
import { GoogleGenAI } from '@google/genai';
const ai = new GoogleGenAI({ apiKey: process.env.GEMINI_API_KEY });
const names = [];
for await (const m of await ai.models.list()) if ((m.supportedActions || []).includes('generateContent')) names.push(m.name.replace('models/', ''));
console.log(names.filter((n) => /gemini/.test(n)).join('\n'));
