// SDK 3.0.0 defaults to API v1. Re-run the models that 404 on v1, with v1beta set in code and via env (7 Nov 2026). Never prints the key.
const { GoogleGenAI } = await import('genai3');
const models = ['gemini-flash-latest', 'gemini-flash-lite-latest', 'gemini-3.1-pro-preview'];
const run = async (label, ai) => { for (const model of models) { try { const r = await Promise.race([ai.models.generateContent({ model, contents: 'Reply with one word: hi', config: { maxOutputTokens: 1 } }), new Promise((_, j) => setTimeout(() => j(new Error('timeout 60s')), 60000))]); console.log(`${label} | ${model} | OK | modelVersion=${r.modelVersion}`); } catch (e) { const m = String(e.message).match(/"message":\s*"([^"]+)/); console.log(`${label} | ${model} | ERR ${e.status ?? ''} | ${(m ? m[1] : String(e.message)).slice(0, 140)}`); } } };
await run("apiVersion: 'v1beta'", new GoogleGenAI({ apiKey: process.env.GEMINI_API_KEY, apiVersion: 'v1beta' }));
process.env.GOOGLE_GENAI_API_VERSION = 'beta';
await run('GOOGLE_GENAI_API_VERSION=beta', new GoogleGenAI({ apiKey: process.env.GEMINI_API_KEY }));
