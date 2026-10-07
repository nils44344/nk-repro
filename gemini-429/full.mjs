import dotenv from 'dotenv'; dotenv.config({ path: '../.env', quiet: true });
import { GoogleGenAI } from '@google/genai';
const ai = new GoogleGenAI({ apiKey: process.env.GEMINI_API_KEY });
try { await ai.models.generateContent({ model: process.argv[2], contents: 'hi', config: { maxOutputTokens: 1 } }); console.log('OK'); }
catch (e) { console.log('class', e.constructor.name, 'status', e.status); try { console.log(JSON.stringify(JSON.parse(e.message), null, 2)); } catch { console.log(e.message); } }
